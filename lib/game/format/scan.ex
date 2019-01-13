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
    context()
    |> assign(:current, room_current(room))
    |> assign_many(:rooms, rooms, &room_in_direction/1)
    |> Format.template("[current][\nrooms]")
  end

  defp room_current(room) do
    context()
    |> assign_many(:players, room.players, &player_line/1)
    |> assign_many(:npcs, room.npcs, &npc_line/1)
    |> Format.template("You look around and see:\n[players\n][npcs\n]")
  end

  defp room_in_direction({direction, room}) do
    context()
    |> assign(:direction, direction)
    |> assign_many(:players, room.players, &player_line/1)
    |> assign_many(:npcs, room.npcs, &npc_line/1)
    |> Format.template("You look {command}#{direction}{/command} and see:\n[players\n][npcs\n]")
  end

  def npc_line(npc) do
    context()
    |> assign(:name, Format.npc_name(npc))
    |> Format.template(" - [name]")
  end

  def player_line(player) do
    context()
    |> assign(:name, Format.player_name(player))
    |> Format.template(" - [name]")
  end
end
