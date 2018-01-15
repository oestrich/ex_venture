defmodule Game.Quest do
  @moduledoc """
  Quest context
  """

  import Ecto.Query

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
  @spec current_step_progress(QuestStep.t(), QuestProgress.t()) :: String.t()
  def current_step_progress(step, quest_progress) do
    case step.type do
      "item/collect" ->
        Map.get(quest_progress.progress, step.id, 0)
      "npc/kill" ->
        Map.get(quest_progress.progress, step.id, 0)
    end
  end
end
