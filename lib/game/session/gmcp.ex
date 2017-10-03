defmodule Game.Session.GMCP do
  @moduledoc """
  Helpers for pushing GMCP data
  """

  use Networking.Socket

  alias Data.Room

  @doc """
  Push Character data (save stats)
  """
  @spec character(state :: map) :: :ok
  def character(%{socket: socket, user: user}) do
    socket |> @socket.push_gmcp("Character", %{name: user.name} |> Poison.encode!())
  end

  @doc """
  Push Character.Vitals data (save stats)
  """
  @spec vitals(state :: map) :: :ok
  def vitals(%{socket: socket, save: save}) do
    socket |> @socket.push_gmcp("Character.Vitals", save.stats |> Poison.encode!())
  end

  @doc """
  Push Room.Info data
  """
  @spec room(state :: map, room :: Room.t) :: :ok
  def room(%{socket: socket}, room) do
    socket |> @socket.push_gmcp("Room.Info", room |> room_info() |> Poison.encode!())
  end

  @doc """
  A character enters a room

  Does not push directly to the socket
  """
  @spec character_enter({:user, map} | {:npc, map}) :: {module :: String.t, data :: map}
  def character_enter({:user, user}) do
    {"Room.Character.Enter", %{type: :player, id: user.id, name: user.name}}
  end
  def character_enter({:npc, npc}) do
    {"Room.Character.Enter", %{type: :npc, id: npc.id, name: npc.name}}
  end

  @doc """
  A character leaves a room

  Does not push directly to the socket
  """
  @spec character_leave({:user, map} | {:npc, map}) :: {module :: String.t, data :: map}
  def character_leave({:user, user}) do
    {"Room.Character.Leave", %{type: :player, id: user.id, name: user.name}}
  end
  def character_leave({:npc, npc}) do
    {"Room.Character.Leave", %{type: :npc, id: npc.id, name: npc.name}}
  end

  defp room_info(room) do
    room
    |> Map.take([:name, :description, :ecology, :zone_id, :x, :y])
    |> Map.merge(%{
      items: render_many(room, :items),
      players: render_many(room, :players),
      npcs: render_many(room, :npcs),
      shops: render_many(room, :shops),
    })
  end

  defp render_many(struct, key) do
    case struct do
      %{^key => data} when data != nil ->
        Enum.map(data, &(%{id: &1.id, name: &1.name}))
      _ -> []
    end
  end
end
