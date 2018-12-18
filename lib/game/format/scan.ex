defmodule Game.Format.Scan do
  @moduledoc """
  Formatting for the scan command
  """

  import Game.Format.Context

  alias Game.Format

  @doc """
  Format the scan for the room you're in
  """
  def room(room, rooms) do
    [
      room_current(room),
      rooms(rooms)
    ]
    |> Enum.join("\n")
    |> String.trim()
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
    context()
    |> assign(:who, who(room))
    |> Format.template("You look around and see:\n[who]")
  end

  defp room_in_direction(direction, room) do
    context()
    |> assign(:direction, direction)
    |> assign(:who, who(room))
    |> Format.template("You look {command}#{direction}{/command} and see:\n[who]")
  end

  defp who(room) do
    Enum.join(npcs(room) ++ players(room), "\n")
  end

  defp npcs(room) do
    Enum.map(room.npcs, fn npc ->
      context()
      |> assign(:name, Format.npc_name(npc))
      |> Format.template(" - [name]")
    end)
  end

  defp players(room) do
    Enum.map(room.players, fn player ->
      context()
      |> assign(:name, Format.player_name(player))
      |> Format.template(" - [name]")
    end)
  end
end
