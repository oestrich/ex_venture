defmodule Game.Format.Scan do
  @moduledoc """
  Formatting for the scan command
  """

  alias Game.Format

  @doc """
  Format the scan for the room you're in
  """
  def room(room, rooms) do
    [
      room_current(room),
      rooms(rooms)
    ] |> Enum.join("\n")
  end

  defp rooms(rooms) do
    rooms
    |> Enum.map(fn {direction, room} ->
      room_in_direction(direction, room)
    end)
    |> Enum.join("\n")
    |> String.trim()
  end

  defp room_current(room) do
    """
    You look around and see:
    #{who(room)}
    """
  end

  defp room_in_direction(direction, room) do
    """
    You look {command}#{direction}{/command} and see:
    #{who(room)}
    """
  end

  defp who(room) do
    Enum.join(npcs(room) ++ players(room), "\n")
  end

  defp npcs(room) do
    Enum.map(room.npcs, fn npc ->
      " - #{Format.name({:npc, npc})}"
    end)
  end

  defp players(room) do
    Enum.map(room.players, fn user ->
      " - #{Format.name({:user, user})}"
    end)
  end
end
