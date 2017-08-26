defmodule Game.Character.Update do
  @moduledoc """
  Helper module for updating character's save and stats
  """

  use Game.Room

  @doc """
  Update a character's stats in the room
  """
  @spec update_character(room_id :: integer, user :: User.t) :: :ok
  def update_character(room_id, user) do
    room_id |> @room.update_character({:user, self(), user})
  end
end
