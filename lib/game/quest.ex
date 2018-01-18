defmodule Game.Quest do
  @moduledoc """
  Quest context
  """

  import Ecto.Query

  alias Data.Quest
  alias Data.QuestProgress
  alias Data.QuestStep
  alias Data.Repo
  alias Data.User

  @doc """
  Get quests for a user, loads from their quest progress.
  """
  @spec for(User.t()) :: [QuestProgress.t()]
  def for(user) do
    QuestProgress
    |> where([qp], qp.user_id == ^user.id)
    |> where([qp], qp.status == "active")
    |> preloads()
    |> Repo.all()
  end

  @doc """
  Find progress of a particular quest for a user
  """
  @spec progress_for(User.t(), integer()) :: QuestProgress.t()
  def progress_for(user, quest_id) do
    QuestProgress
    |> where([qp], qp.user_id == ^user.id and qp.quest_id == ^quest_id)
    |> preloads()
    |> preload([quest: [quest_steps: [:item, :npc]]])
    |> Repo.one()
  end

  defp preloads(quest), do: quest |> preload([quest: [:giver]])

  @doc """
  Get the current progress of a user on a given step of a quest
  """
  @spec current_step_progress(QuestStep.t(), QuestProgress.t(), Save.t()) :: String.t()
  def current_step_progress(step, quest_progress, save) do
    case step.type do
      "item/collect" ->
        save.items
        |> Enum.filter(fn (item) ->
          item.id == step.item_id
        end)
        |> length()
      "npc/kill" ->
        Map.get(quest_progress.progress, step.id, 0)
    end
  end

  @doc """
  Check if the quest progress is complete, all steps have been completed
  """
  @spec requirements_complete?(QuestProgress.t(), Save.t()) :: boolean()
  def requirements_complete?(quest_progress, save) do
    %{quest_steps: quest_steps} = quest_progress.quest

    Enum.all?(quest_steps, fn (step) ->
      requirement_complete?(step, quest_progress, save)
    end)
  end

  @doc """
  Check if a single step is complete
  """
  @spec requirement_complete?(QuestStep.t(), QuestProgress.t(), Save.t()) :: boolean()
  def requirement_complete?(step, progress, save) do
    current_step_progress(step, progress, save) >= step.count
  end

  @doc """
  Mark a quest as complete and update the user's save
  """
  @spec complete(QuestProgress.t(), Save.t()) :: Save.t()
  def complete(progress, save) do
    changeset = progress |> QuestProgress.changeset(%{status: "complete"})
    case changeset |> Repo.update() do
      {:ok, _progress} ->
        save = filter_step_items(progress, save)
        {:ok, save}
      {:error, _} -> :error
    end
  end

  defp filter_step_items(progress, save) do
    %{quest_steps: quest_steps} = progress.quest

    quest_steps
    |> Enum.filter(fn (step) ->
      step.type == "item/collect"
    end)
    |> Enum.reduce(save, fn (step, save) ->
      items =
        save.items
        |> Enum.filter(fn (item) ->
          item.id == step.item_id
        end)
        |> Enum.take(step.count)
        |> Enum.reduce(save.items, fn (item, items) ->
          List.delete(items, item)
        end)

      %{save | items: items}
    end)
  end

  @doc """
  Track quest progress for the user
  """
  @spec track_progress(User.t(), any()) :: :ok
  def track_progress(user, {:npc, npc}) do
    QuestProgress
    |> join(:left, [qp], q in assoc(qp, :quest))
    |> join(:left, [qp, q], qs in assoc(q, :quest_steps))
    |> where([qp, q, qs], qp.user_id == ^user.id and qs.type == "npc/kill" and qs.npc_id == ^npc.id)
    |> select([qp, q, qs], [qp.id, qs.id])
    |> Repo.all()
    |> Enum.each(&track_step/1)

    :ok
  end

  defp track_step([progress_id, step_id]) do
    quest_progress = Repo.get(QuestProgress, progress_id)
    step = Repo.get(QuestStep, step_id)
    step_progress = Map.get(quest_progress.progress, step.id, 0)
    case step_progress < step.count do
      false -> :ok
      true ->
        progress = quest_progress.progress |> Map.put(step_id, step_progress + 1)
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
  @spec next_available_quest_from(NPC.t(), User.t()) :: {:ok, Quest.t()} | {:error, :no_quests} | {:error, :in_progress}
  def next_available_quest_from(npc, user) do
    Quest
    |> where([q], q.giver_id == ^npc.id)
    |> join(:left, [q], qr in assoc(q, :parents))
    |> having([q, qr], count(qr.id) == 0)
    |> group_by([q, qr], q.id)
    |> order_by([q, qr], q.id)
    |> preload([:children])
    |> Repo.all()
    |> _find_next_quest(user)
  end

  defp _find_next_quest(quests, user) do
    case _check_quests(quests, user) do
      nil ->
        case _check_child_quests(quests, user) do
          nil ->
            {:error, :no_quests}

          {:error, :in_progress} ->
            {:error, :in_progress}

          {:ok, quest} ->
            {:ok, quest}
        end

      {:error, :in_progress} ->
        {:error, :in_progress}

      {:ok, quest} ->
        {:ok, quest}
    end
  end

  defp _check_child_quests(quests, user) do
    quests = Enum.map(quests, fn (quest) ->
      quest |> Repo.preload(:children)
    end)

    quest =
      Enum.find_value(quests, fn (quest) ->
        _check_quests(quest.children, user)
      end)

    case quest do
      nil ->
        Enum.find_value(quests, fn (quest) ->
          _check_child_quests(quest.children, user)
        end)

      {:error, :in_progress} ->
        {:error, :in_progress}

      {:ok, quest} ->
        {:ok, quest}
    end
  end

  defp _check_quests(quests, user) do
    Enum.find_value(quests, fn (quest) ->
      case progress_for(user, quest.id) do
        nil ->
          {:ok, quest}

        %{status: "complete"} ->
          nil

        %{status: "active"} ->
          {:error, :in_progress}
      end
    end)
  end
end
