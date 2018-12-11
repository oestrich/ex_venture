defmodule Game.Format.Quests do
  @moduledoc """
  Format function for quests
  """

  alias Game.Format
  alias Game.Format.Rooms
  alias Game.Format.Table
  alias Game.Quest

  @doc """
  Format a quest name

    iex> Game.Format.quest_name(%{name: "Into the Dungeon"})
    "{quest}Into the Dungeon{/quest}"
  """
  def quest_name(quest) do
    "{quest}#{quest.name}{/quest}"
  end

  @doc """
  Format the status of a player's quests
  """
  @spec quest_progress([QuestProgress.t()]) :: String.t()
  def quest_progress(quests) do
    rows =
      quests
      |> Enum.map(fn %{status: status, quest: quest} ->
        [to_string(quest.id), quest.name, quest.giver.name, status]
      end)

    Table.format("You have #{length(quests)} active quests.", rows, [5, 30, 20, 10])
  end

  @doc """
  Format the status of a player's quest
  """
  @spec quest_detail(QuestProgress.t(), Save.t()) :: String.t()
  def quest_detail(progress, save) do
    %{quest: quest} = progress
    steps = quest.quest_steps |> Enum.map(&quest_step(&1, progress, save))
    header = "#{quest.name} - #{progress.status}"

    """
    #{header}
    #{header |> Format.underline()}

    #{quest.description}

    #{steps |> Enum.join("\n")}
    """
    |> String.trim()
    |> Format.resources()
  end

  defp quest_step(step, progress, save) do
    case step.type do
      "item/collect" ->
        current_step_progress = Quest.current_step_progress(step, progress, save)
        " - Collect #{item_name(step.item)} - #{current_step_progress}/#{step.count}"

      "item/give" ->
        current_step_progress = Quest.current_step_progress(step, progress, save)

        " - Give #{item_name(step.item)} to #{npc_name(step.npc)} - #{current_step_progress}/#{
          step.count
        }"

      "item/have" ->
        current_step_progress = Quest.current_step_progress(step, progress, save)
        " - Have #{item_name(step.item)} - #{current_step_progress}/#{step.count}"

      "npc/kill" ->
        current_step_progress = Quest.current_step_progress(step, progress, save)
        " - Kill #{npc_name(step.npc)} - #{current_step_progress}/#{step.count}"

      "room/explore" ->
        current_step_progress = Quest.current_step_progress(step, progress, save)
        " - Explore #{room_name(step.room)} - #{current_step_progress}"
    end
  end

  defp item_name(item), do: Format.item_name(item)

  defp npc_name(npc), do: Format.npc_name(npc)

  defp room_name(room), do: Rooms.room_name(room)
end
