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

  defp room_info(room = %Room{}) do
    basics = Map.take(room, [:name, :description, :ecology, :zone_id, :x, :y])
    Map.merge(basics, %{
      items: Enum.map(room.items, &(%{id: &1.id, name: &1.name})),
      players: Enum.map(room.players, &(%{id: &1.id, name: &1.name})),
      npcs: Enum.map(room.npcs, &(%{id: &1.id, name: &1.name})),
      shops: Enum.map(room.shops, &(%{id: &1.id, name: &1.name})),
    })
  end
end
