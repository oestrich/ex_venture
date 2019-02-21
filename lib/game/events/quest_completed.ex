defmodule Game.Events.QuestCompleted do
  @moduledoc """
  Event for completing a quest
  """

  defstruct [:player, :quest, type: "quest/completed"]
end
