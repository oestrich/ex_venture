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
  alias Game.Session

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
    |> Repo.one()
  end

  @doc """
  Get the current tracked quest
  """
  @spec current_tracked_quest(User.t()) :: QuestProgress.t() | nil
  def current_tracked_quest(user) do
    QuestProgress
    |> where([qp], qp.user_id == ^user.id and qp.is_tracking == true and qp.status != "complete")
    |> preloads()
    |> limit(1)
    |> Repo.one()
  end

  defp preloads(quest) do
    quest |> preload(quest: [:giver, quest_steps: [:item, :npc]])
  end

  @doc """
  Start a quest for a user
  """
  @spec start_quest(User.t(), Quest.t()) :: :ok
  def start_quest(user, quest_id) when is_integer(quest_id) do
    quest = Quest |> Repo.get(quest_id)
    start_quest(user, quest)
  end

  def start_quest(user, quest) do
    changeset =
      %QuestProgress{}
      |> QuestProgress.changeset(%{
        user_id: user.id,
        quest_id: quest.id,
        status: "active"
      })

    case changeset |> Repo.insert() do
      {:ok, _} ->
        Session.notify(user, {"quest/new", quest})
        :ok

      {:error, _} ->
        :error
    end
  end

  @doc """
  Get the current progress of a user on a given step of a quest
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

      "item/have" ->
        save.items
        |> Enum.filter(fn item ->
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

    Enum.all?(quest_steps, fn step ->
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
  Track quest progress for the user
  """
  @spec track_progress(User.t(), any()) :: :ok
  def track_progress(user, {:npc, npc}) do
    QuestProgress
    |> join(:left, [qp], q in assoc(qp, :quest))
    |> join(:left, [qp, q], qs in assoc(q, :quest_steps))
    |> where(
      [qp, q, qs],
      qp.user_id == ^user.id and qs.type == "npc/kill" and qs.npc_id == ^npc.id
    )
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
      false ->
        :ok

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
  @spec next_available_quest_from(NPC.t(), User.t()) :: {:ok, Quest.t()} | {:error, :no_quests}
  def next_available_quest_from(npc, user) do
    case find_available_quests(npc, user) do
      [] ->
        {:error, :no_quests}

      [quest | _] ->
        {:ok, quest}
    end
  end

  defp find_available_quests(npc, user) do
    Quest
    |> where([q], q.giver_id == ^npc.id)
    |> where([q], q.level <= ^user.save.level)
    |> order_by([q], q.id)
    |> preload([:parent_relations])
    |> Repo.all()
    |> Enum.filter(&filter_progress(&1, user))
    |> Enum.filter(&filter_parent_not_complete(&1, user))
  end

  # filter out quests with progress
  defp filter_progress(quest, user) do
    case progress_for(user, quest.id) do
      nil -> true
      _ -> false
    end
  end

  # filter out quests that have incomplete parents
  defp filter_parent_not_complete(quest, user) do
    Enum.all?(quest.parent_relations, fn parent_relation ->
      case progress_for(user, parent_relation.parent_id) do
        %{status: "complete"} -> true
        _ -> false
      end
    end)
  end

  @doc """
  Set a quest as being tracked, clears other quests they have and sets this one
  """
  @spec track_quest(User.t(), Quest.t()) :: :ok | {:error, :not_started}
  def track_quest(user, quest_id) do
    case progress_for(user, quest_id) do
      nil -> {:error, :not_started}
      quest_progress -> _track_quest(user, quest_progress)
    end
  end

  defp _track_quest(user, quest_progress) do
    reset_query =
      QuestProgress
      |> where([qp], qp.user_id == ^user.id and qp.quest_id == ^quest_progress.quest_id)

    track_changeset = quest_progress |> QuestProgress.changeset(%{is_tracking: true})

    multi =
      Ecto.Multi.new
      |> Ecto.Multi.update_all(:reset_tracking, reset_query, set: [is_tracking: false])
      |> Ecto.Multi.update(:track, track_changeset)

    case multi |> Repo.transaction() do
      {:ok, _} -> {:ok, quest_progress}
      _ -> :error
    end
  end
end
