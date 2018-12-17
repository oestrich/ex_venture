defmodule Game.Format.Quests do
  @moduledoc """
  Format function for quests
  """

  import Game.Format.Context

  alias Game.Format
  alias Game.Format.Table
  alias Game.Quest

  @doc """
  Format a quest name

    iex> Game.Format.quest_name(%{name: "Into the Dungeon"})
    "{quest}Into the Dungeon{/quest}"
  """
  def quest_name(quest) do
    context()
    |> assign(:name, quest.name)
    |> Format.template("{quest}[name]{/quest}")
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

    context()
    |> assign(:name, quest_name(quest))
    |> assign(:progress, progress.status)
    |> assign(:underline, Format.underline("#{quest.name} - #{progress.status}"))
    |> assign(:description, quest.description)
    |> assign(:steps, Enum.join(steps, "\n"))
    |> Format.template(template("quest"))
    |> Format.resources()
  end

  def quest_step(step = %{type: "item/collect"}, progress, save) do
    current_step_progress = Quest.current_step_progress(step, progress, save)

    context()
    |> assign(:item_name, Format.item_name(step.item))
    |> assign(:progress, current_step_progress)
    |> assign(:total, step.count)
    |> Format.template(" - Collect [item_name] - [progress]/[total]")
  end

  def quest_step(step = %{type: "item/give"}, progress, save) do
    current_step_progress = Quest.current_step_progress(step, progress, save)

    context()
    |> assign(:item_name, Format.item_name(step.item))
    |> assign(:npc_name, Format.npc_name(step.npc))
    |> assign(:progress, current_step_progress)
    |> assign(:total, step.count)
    |> Format.template(" - Give [item_name] to [npc_name] - [progress]/[total]")
  end

  def quest_step(step = %{type: "item/have"}, progress, save) do
    current_step_progress = Quest.current_step_progress(step, progress, save)

    context()
    |> assign(:item_name, Format.item_name(step.item))
    |> assign(:progress, current_step_progress)
    |> assign(:total, step.count)
    |> Format.template(" - Have [item_name] - [progress]/[total]")
  end

  def quest_step(step = %{type: "npc/kill"}, progress, save) do
    current_step_progress = Quest.current_step_progress(step, progress, save)

    context()
    |> assign(:npc_name, Format.npc_name(step.npc))
    |> assign(:progress, current_step_progress)
    |> assign(:total, step.count)
    |> Format.template(" - Kill [npc_name] - [progress]/[total]")
  end

  def quest_step(step = %{type: "room/explore"}, progress, save) do
    current_step_progress = Quest.current_step_progress(step, progress, save)

    context()
    |> assign(:room_name, Format.room_name(step.room))
    |> assign(:progress, current_step_progress)
    |> Format.template(" - Explore [room_name] - [progress]")
  end

  def template("quest") do
    """
    [name] - [progress]
    [underline]

    [description]

    [steps]
    """
  end
end
