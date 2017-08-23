defmodule Test.Game.Room do
  alias Data.Room

  def start_link() do
    Agent.start_link(fn () -> %{room: _room()} end, name: __MODULE__)
  end

  def _room() do
    %Room{
      name: "Hallway",
      description: "An empty hallway",
      north_id: 10,
      west_id: 11,
      players: [],
      items: [%Data.Item{id: 15, name: "Short Sword", description: "A simple blade", keywords: ["sword"]}],
    }
  end

  def set_room(room) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :room, room) end)
  end

  def look(_id) do
    start_link()
    Agent.get(__MODULE__, &(&1.room))
  end

  def enter(_id, {:user, _session, _user}) do
  end

  def leave(id, user) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      leaves = Map.get(state, :leave, [])
      Map.put(state, :leave, leaves ++ [{id, user}])
    end)
  end

  def get_leaves() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :leave, []) end)
  end

  def say(id, _session, message) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      says = Map.get(state, :say, [])
      Map.put(state, :say, says ++ [{id, message}])
    end)
  end

  def get_says() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :say, []) end)
  end

  def set_pick_up(response) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :pick_up, response) end)
  end

  def pick_up(_id, item) do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :pick_up, {:ok, item}) end)
  end
end
