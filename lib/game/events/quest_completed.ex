defmodule Game.Events.QuestCompleted do
  @moduledoc """
  Event for receiving a new piece of mail
  """

  defstruct [:player, :quest, type: "quest/completed"]
end
