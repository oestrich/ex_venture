defmodule Game.Events.RoomEntered do
  @moduledoc """
  Event for a character entering a room
  """

  defstruct [:character, :reason, type: "room/entered"]
end
