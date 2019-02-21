defmodule Game.Events.RoomLeft do
  @moduledoc """
  Event for a character entering a room
  """

  defstruct [:character, :reason, type: "room/left"]
end
