defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  use Supervisor

  alias Game.Room

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Return all rooms that are currently online
  """
  @spec rooms() :: [pid]
  def rooms() do
    Supervisor.which_children(Game.Zone)
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(_) do
    children = Room.all |> Enum.map(fn (room) ->
      worker(Room, [room], id: room.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
