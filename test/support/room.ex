defmodule Test.Game.Room do
  alias Data.Room

  def start_link() do
    Agent.start_link(fn () -> %{room: _room()} end, name: __MODULE__)
  end

  def _room() do
    %Room{
      id: 1,
      name: "Hallway",
      description: "An empty hallway",
      exits: [%{north_id: 2, south_id: 1}],
      zone_id: 1,
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

  def enter(id, who) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      enters = Map.get(state, :enter, [])
      Map.put(state, :enter, enters ++ [{id, who}])
    end)
  end

  def get_enters() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :enter, []) end)
  end

  def clear_enters() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :enter, []) end)
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

  def clear_leaves() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :leave, []) end)
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

  def clear_says() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :say, []) end)
  end

  def emote(id, _session, message) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      emotes = Map.get(state, :emote, [])
      Map.put(state, :emote, emotes ++ [{id, message}])
    end)
  end

  def get_emotes() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :emote, []) end)
  end

  def update_character(id, character) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      update_characters = Map.get(state, :update_character, [])
      Map.put(state, :update_character, update_characters ++ [{id, character}])
    end)
  end

  def get_update_characters() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :update_character, []) end)
  end

  def clear_update_characters() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :update_character, []) end)
  end

  def set_pick_up(response) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :pick_up, response) end)
  end

  def pick_up(_id, item) do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :pick_up, {:ok, item}) end)
  end

  def clear_pick_up() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.delete(state, :pick_up) end)
  end

  def drop(id, who, item) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      drops = Map.get(state, :drop, [])
      Map.put(state, :drop, drops ++ [{id, who, item}])
    end)
  end

  def get_drops() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :drop, []) end)
  end

  def clear_drops() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :drop, []) end)
  end
end
