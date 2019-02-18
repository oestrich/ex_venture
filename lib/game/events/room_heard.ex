defmodule Game.Events.RoomHeard do
  @moduledoc """
  Event for a message heard in a room
  """

  defstruct [:character, :message, type: "room/heard"]
end
