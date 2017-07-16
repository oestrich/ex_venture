defmodule Test.Game.Room do
  alias Data.Room

  def start_link() do
    Agent.start_link(fn () -> _room() end, name: __MODULE__)
  end

  def _room() do
    %Room{
      name: "Hallway",
      description: "An empty hallway",
      north_id: 10,
      west_id: 11,
      players: [],
    }
  end

  def set_room(room) do
    start_link()
    Agent.update(__MODULE__, fn (_) -> room end)
  end

  def look(_id) do
    start_link()
    Agent.get(__MODULE__, &(&1))
  end

  def enter(_id, _user) do
  end

  def leave(_id, _user) do
  end
end
