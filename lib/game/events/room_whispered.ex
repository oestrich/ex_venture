defmodule Game.Events.RoomWhispered do
  @moduledoc """
  Event for being whispered to in a room
  """

  defstruct [:character, :message, type: "room/whispered"]
end
