defmodule Game.Events.RoomOverheard do
  @moduledoc """
  Event for a message heard in a room
  """

  defstruct [:character, :characters, :message, type: "room/overheard"]
end
