defmodule Game.Room.Supervisor do
  @moduledoc """
  Supervisor for Rooms
  """

  use Supervisor

  alias Game.Room
  alias Game.Zone.Repo

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  @doc """
  Return all zones
  """
  @spec all() :: [map]
  def all() do
    Repo.all()
  end

  @doc """
  Return all rooms that are currently online
  """
  @spec rooms(pid :: pid) :: [pid]
  def rooms(pid) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(zone) do
    children = zone.id
    |> Room.for_zone()
    |> Enum.map(fn (room) ->
      worker(Room, [room], id: room.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
