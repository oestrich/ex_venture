defmodule Game.Events.QuestReceived do
  @moduledoc """
  Event for receiving a new piece of mail
  """

  defstruct [:quest, type: "quest/recieved"]
end
