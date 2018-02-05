defmodule Test.Game.Room do
  alias Data.Room

  def start_link() do
    Agent.start_link(fn () -> %{room: _room(), rooms: %{}} end, name: __MODULE__)
  end

  def _room() do
    %Room{
      id: 1,
      name: "Hallway",
      description: "An empty hallway",
      exits: [%{north_id: 2, south_id: 1}],
      zone_id: 1,
      players: [],
      npcs: [],
      items: [],
      shops: [],
      x: 0,
      y: 0,
      map_layer: 0,
    }
  end

  def link(_id), do: :ok

  def unlink(_id), do: :ok

  def crash(id) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      crashes = Map.get(state, :crash, [])
      Map.put(state, :crash, crashes ++ [id])
    end)
  end

  def get_crashes() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :crash, []) end)
  end

  def clear_crashes() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :crash, []) end)
  end

  def set_room(room, opts \\ []) do
    start_link()

    Agent.update(__MODULE__, fn (state) ->
      rooms =
        case Keyword.get(opts, :multiple, false) do
          true ->
            state
            |> Map.get(:rooms, %{})
            |> Map.put(room.id, room)
          false ->
            %{}
        end

      state
      |> Map.put(:room, room)
      |> Map.put(:rooms, rooms)
    end)
  end

  def look(id) do
    start_link()
    Agent.get(__MODULE__, fn (state) ->
      Map.get(state.rooms, id, state.room)
    end)
  end

  def enter(id, who, reason \\ :enter) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      enters = Map.get(state, :enter, [])
      Map.put(state, :enter, enters ++ [{id, who, reason}])
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

  def leave(id, user, reason \\ :leave) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      leaves = Map.get(state, :leave, [])
      Map.put(state, :leave, leaves ++ [{id, user, reason}])
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

  def notify(id, _sender, event) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      notifys = Map.get(state, :notify, [])
      Map.put(state, :notify, notifys ++ [{id, event}])
    end)
  end

  def get_notifies() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :notify, []) end)
  end

  def clear_notifies() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :notify, []) end)
  end

  def say(id, _sender, message) do
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

  def emote(id, _sender, message) do
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

  def clear_emotes() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :emote, []) end)
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

  def set_pick_up_currency(response) do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :pick_up_currency, response) end)
  end

  def pick_up_currency(_id) do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :pick_up_currency) end)
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

  def drop_currency(id, who, amount) do
    start_link()
    Agent.update(__MODULE__, fn (state) ->
      drops = Map.get(state, :drop_currency, [])
      Map.put(state, :drop_currency, drops ++ [{id, who, amount}])
    end)
  end

  def get_drop_currencies() do
    start_link()
    Agent.get(__MODULE__, fn (state) -> Map.get(state, :drop_currency, []) end)
  end

  def clear_drop_currencies() do
    start_link()
    Agent.update(__MODULE__, fn (state) -> Map.put(state, :drop_currency, []) end)
  end
end
