defmodule Game.Quest do
  @moduledoc """
  Quest context
  """

  import Ecto.Query

  alias Data.Character
  alias Data.Quest
  alias Data.QuestProgress
  alias Data.QuestStep
  alias Data.Repo
  alias Data.User
  alias Game.Item
  alias Game.Session

  @doc """
  Check if a quest is complete
  """
  def complete?(quest_progress) do
    quest_progress.status == "complete"
  end

  @doc """
  Get quests for a player, loads from their quest progress.
  """
  @spec for(User.t()) :: [QuestProgress.t()]
  def for(player) do
    QuestProgress
    |> where([qp], qp.user_id == ^player.id)
    |> where([qp], qp.status == "active")
    |> preloads()
    |> Repo.all()
  end

  @doc """
  Find progress of a particular quest for a player
  """
  @spec progress_for(User.t(), integer()) :: {:ok, QuestProgress.t()} | {:error, :invalid_id} | {:error, :not_found}
  def progress_for(player, quest_id) do
    case Ecto.Type.cast(:integer, quest_id) do
      {:ok, quest_id} ->
        quest =
          QuestProgress
          |> where([qp], qp.user_id == ^player.id and qp.quest_id == ^quest_id)
          |> preloads()
          |> Repo.one()

        case quest do
          nil ->
            {:error, :not_found}

          quest ->
            {:ok, quest}
        end

      :error ->
        {:error, :invalid_id}
    end
  end

  @doc """
  Get the current tracked quest
  """
  @spec current_tracked_quest(User.t()) :: QuestProgress.t() | nil
  def current_tracked_quest(player) do
    QuestProgress
    |> where([qp], qp.user_id == ^player.id and qp.is_tracking == true and qp.status != "complete")
    |> preloads()
    |> limit(1)
    |> Repo.one()
  end

  defp preloads(quest) do
    quest |> preload(quest: [:giver, quest_steps: [:item, :npc, :room]])
  end

  @doc """
  Start a quest for a player
  """
  @spec start_quest(User.t(), Quest.t()) :: :ok
  def start_quest(player, quest_id) when is_integer(quest_id) do
    quest = Quest |> Repo.get(quest_id)
    start_quest(player, quest)
  end

  def start_quest(player, quest) do
    changeset =
      %QuestProgress{}
      |> QuestProgress.changeset(%{
        user_id: player.id,
        quest_id: quest.id,
        status: "active"
      })

    case changeset |> Repo.insert() do
      {:ok, _} ->
        player = Character.from_user(player)
        Session.notify(player, {"quest/new", quest})
        :ok

      {:error, _} ->
        :error
    end
  end

  @doc """
  Get the current progress of a player on a given step of a quest
  """
  @spec current_step_progress(QuestStep.t(), QuestProgress.t(), Save.t()) :: String.t()
  def current_step_progress(step, quest_progress, save) do
    case step.type do
      "item/collect" ->
        save.items
        |> Enum.filter(fn item ->
          item.id == step.item_id
        end)
        |> length()

      "item/give" ->
        Map.get(quest_progress.progress, step.id, 0)

      "item/have" ->
        item_have_progress(step, quest_progress, save)

      "npc/kill" ->
        Map.get(quest_progress.progress, step.id, 0)

      "room/explore" ->
        quest_progress.progress
        |> Map.get(step.id, %{explored: false})
        |> Map.get(:explored)
    end
  end

  defp item_have_progress(step, quest_progress, save) do
    case complete?(quest_progress) do
      true ->
        step.count

      false ->
        save
        |> Item.all_items()
        |> Enum.filter(fn item ->
          item.id == step.item_id
        end)
        |> length()
    end
  end

  @doc """
  Filter active quests for a list of NPCs
  """
  @spec filter_active_quests_for_room([QuestProgress.t()], [integer()]) :: [QuestProgress.t()]
  def filter_active_quests_for_room(quest_progress, npc_ids) do
    Enum.filter(quest_progress, fn progress ->
      progress.quest.giver_id in npc_ids
    end)
  end

  @doc """
  Find a quest ready to be completed by a player
  """
  @spec find_quest_for_ready_to_complete([QuestProgress.t()], Save.t()) :: {:ok, QuestProgress.t()} | {:error, :none}
  def find_quest_for_ready_to_complete(quest_progress, save) do
    progress =
      Enum.find(quest_progress, fn progress ->
        requirements_complete?(progress, save)
      end)

    case progress do
      nil ->
        {:error, :none}

      progress ->
        {:ok, progress}
    end
  end

  @doc """
  Check if the quest progress is complete, all steps have been completed
  """
  @spec requirements_complete?(QuestProgress.t(), Save.t()) :: boolean()
  def requirements_complete?(quest_progress, save) do
    %{quest_steps: quest_steps} = quest_progress.quest

    Enum.all?(quest_steps, fn step ->
      requirement_complete?(step, quest_progress, save)
    end)
  end

  @doc """
  Check if a single step is complete
  """
  @spec requirement_complete?(QuestStep.t(), QuestProgress.t(), Save.t()) :: boolean()
  def requirement_complete?(step = %{type: "room/explore"}, progress, save) do
    current_step_progress(step, progress, save)
  end

  def requirement_complete?(step, progress, save) do
    current_step_progress(step, progress, save) >= step.count
  end

  @doc """
  Mark a quest as complete and update the player's save
  """
  @spec complete(QuestProgress.t(), Save.t()) :: Save.t()
  def complete(progress, save) do
    changeset = progress |> QuestProgress.changeset(%{status: "complete"})

    case changeset |> Repo.update() do
      {:ok, _progress} ->
        save = filter_step_items(progress, save)
        {:ok, save}

      {:error, _} ->
        :error
    end
  end

  defp filter_step_items(progress, save) do
    %{quest_steps: quest_steps} = progress.quest

    quest_steps
    |> Enum.filter(fn step ->
      step.type == "item/collect"
    end)
    |> Enum.reduce(save, fn step, save ->
      items =
        save.items
        |> Enum.filter(fn item ->
          item.id == step.item_id
        end)
        |> Enum.take(step.count)
        |> Enum.reduce(save.items, fn item, items ->
          List.delete(items, item)
        end)

      %{save | items: items}
    end)
  end

  @doc """
  Track quest progress for the player
  """
  @spec track_progress(User.t(), any()) :: :ok
  def track_progress(player, {:item, item_instance, npc}) do
    QuestProgress
    |> join(:left, [qp], q in assoc(qp, :quest))
    |> join(:left, [qp, q], qs in assoc(q, :quest_steps))
    |> where(
      [qp, q, qs],
      qp.user_id == ^player.id and qs.type == "item/give" and qs.npc_id == ^npc.id and
        qs.item_id == ^item_instance.id
    )
    |> select([qp, q, qs], [qp.id, qs.id])
    |> Repo.all()
    |> Enum.each(&track_step/1)

    :ok
  end

  def track_progress(player, {:npc, npc}) do
    QuestProgress
    |> where([qp], qp.status == "active")
    |> join(:left, [qp], q in assoc(qp, :quest))
    |> join(:left, [qp, q], qs in assoc(q, :quest_steps))
    |> where(
      [qp, q, qs],
      qp.user_id == ^player.id and qs.type == "npc/kill" and qs.npc_id == ^npc.id
    )
    |> select([qp, q, qs], [qp.id, qs.id])
    |> Repo.all()
    |> Enum.each(&track_step/1)

    :ok
  end

  # overworld room's don't track progress yet
  def track_progress(_player, {:room, "overworld:" <> _id}) do
    :ok
  end

  def track_progress(player, {:room, room_id}) do
    QuestProgress
    |> where([qp], qp.status == "active")
    |> join(:left, [qp], q in assoc(qp, :quest))
    |> join(:left, [qp, q], qs in assoc(q, :quest_steps))
    |> where(
      [qp, q, qs],
      qp.user_id == ^player.id and qs.type == "room/explore" and qs.room_id == ^room_id
    )
    |> select([qp, q, qs], [qp.id, qs.id])
    |> Repo.all()
    |> Enum.each(&track_room_step/1)

    :ok
  end

  defp track_step([progress_id, step_id]) do
    quest_progress = Repo.get(QuestProgress, progress_id)
    step = Repo.get(QuestStep, step_id)
    step_progress = Map.get(quest_progress.progress, step.id, 0)

    case step_progress < step.count do
      false ->
        :ok

      true ->
        progress = quest_progress.progress |> Map.put(step_id, step_progress + 1)

        quest_progress
        |> QuestProgress.changeset(%{progress: progress})
        |> Repo.update()
    end
  end

  # Update room steps to be explored
  defp track_room_step([progress_id, step_id]) do
    quest_progress = Repo.get(QuestProgress, progress_id)
    step = Repo.get(QuestStep, step_id)
    step_progress = Map.get(quest_progress.progress, step.id, %{explored: false})

    case step_progress do
      %{explored: true} ->
        :ok

      _ ->
        progress = quest_progress.progress |> Map.put(step_id, %{explored: true})

        quest_progress
        |> QuestProgress.changeset(%{progress: progress})
        |> Repo.update()
    end
  end

  @doc """
  Get the next available quest from the npc

  This will continue to look down all available quests that the NPC could give out until
  an available one is found.
  """
  @spec next_available_quest_from(NPC.t(), User.t()) :: {:ok, Quest.t()} | {:error, :no_quests}
  def next_available_quest_from(npc, player) do
    case find_available_quests(npc, player) do
      [] ->
        {:error, :no_quests}

      [quest | _] ->
        {:ok, quest}
    end
  end

  defp find_available_quests(npc, player) do
    Quest
    |> where([q], q.giver_id == ^npc.id)
    |> where([q], q.level <= ^player.save.level)
    |> order_by([q], [q.level, q.id])
    |> preload([:parent_relations])
    |> Repo.all()
    |> Enum.filter(&filter_progress(&1, player))
    |> Enum.filter(&filter_parent_not_complete(&1, player))
  end

  # filter out quests with progress
  defp filter_progress(quest, player) do
    case progress_for(player, quest.id) do
      {:error, :not_found} ->
        true

      {:ok, _progress} ->
        false
    end
  end

  # filter out quests that have incomplete parents
  defp filter_parent_not_complete(quest, player) do
    Enum.all?(quest.parent_relations, fn parent_relation ->
      case progress_for(player, parent_relation.parent_id) do
        {:ok, %{status: "complete"}} ->
          true

        _ ->
          false
      end
    end)
  end

  @doc """
  Set a quest as being tracked, clears other quests they have and sets this one
  """
  @spec track_quest(User.t(), Quest.t()) :: :ok | {:error, :not_started}
  def track_quest(player, quest_id) do
    case progress_for(player, quest_id) do
      {:ok, quest_progress} ->
        _track_quest(player, quest_progress)

      {:error, :not_found} ->
        {:error, :not_started}

      {:error, :invalid_id} ->
        {:error, :not_started}
    end
  end

  defp _track_quest(player, quest_progress) do
    reset_query = QuestProgress |> where([qp], qp.user_id == ^player.id)

    track_changeset =
      quest_progress
      |> Map.put(:is_tracking, false)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_change(:is_tracking, true)

    Repo.transaction(fn ->
      Repo.update_all(reset_query, set: [is_tracking: false])
      Repo.update(track_changeset)
    end)

    {:ok, quest_progress}
  end
end
