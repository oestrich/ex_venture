defmodule Game.Zone do
  use Supervisor

  alias Game.Room

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = Room.all |> Enum.map(fn (room) ->
      worker(Room, [room], id: room.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
