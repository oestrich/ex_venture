defmodule Game.Events.QuestReceived do
  @moduledoc """
  Event for receiving a new quest
  """

  defstruct [:quest, type: "quest/recieved"]
end
