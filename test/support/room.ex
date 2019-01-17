defmodule Test.Game.Room do
  alias Data.Exit
  alias Game.Environment

  def start_link() do
    Agent.start_link(fn () ->
      %{
        offline: false,
        room: _room(),
        rooms: %{},
      }
    end, name: __MODULE__)
  end

  def _room() do
    %Environment.State.Room{
      id: 1,
      name: "Hallway",
      description: "An empty hallway",
      zone_id: 1,
      zone: %{id: 1, name: "A zone"},
      features: [],
      items: [],
      shops: [],
      x: 0,
      y: 0,
      map_layer: 0,
      exits: [%Exit{has_door: false, direction: "north", start_id: 1, finish_id: 2}],
      players: [],
      npcs: [],
    }
  end

  def link(_id), do: :ok

  def unlink(_id), do: :ok

  def crash(id) do
    send(self(), {:crash, id})
  end

  def set_room(:offline) do
    start_link()

    Agent.update(__MODULE__, fn (state) ->
      Map.put(state, :offline, true)
    end)
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
      |> Map.put(:offline, false)
      |> Map.put(:room, room)
      |> Map.put(:rooms, rooms)
    end)
  end

  def look(id) do
    start_link()
    Agent.get(__MODULE__, fn (state) ->
      case state.offline do
        true ->
          {:error, :room_offline}

        false ->
          {:ok, Map.get(state.rooms, id, state.room)}
      end
    end)
  end

  def enter(id, character, reason \\ :enter) do
    send(self(), {:enter, {id, character, reason}})
  end

  def leave(id, character, reason \\ :leave) do
    send(self(), {:leave, {id, character, reason}})
  end

  def notify(id, sender, event) do
    send(self(), {:notify, {id, sender, event}})
  end

  def say(room_id, sender, message) do
    send(self(), {:say, {room_id, sender, message}})
  end

  def emote(room_id, sender, message) do
    send(self(), {:emote, {room_id, sender, message}})
  end

  def update_character(id, character) do
    send(self(), {:character, {id, character}})
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
    send(self(), {:drop, {id, who, item}})
  end

  def drop_currency(id, who, amount) do
    send(self(), {:drop, {id, who, {:currency, amount}}})
  end

  defmodule FakeRoom do
    use GenServer

    def start_link(state) do
      GenServer.start_link(__MODULE__, state)
    end

    @impl true
    def init(state) do
      {:ok, Enum.into(state, %{})}
    end
  end

  defmodule Helpers do
    defmacro assert_drop(message) do
      quote do
        assert_received {:drop, unquote(message)}
      end
    end

    defmacro refute_drop(message) do
      quote do
        refute_receive {:drop, unquote(message)}, 50
      end
    end

    defmacro assert_emote(emote) do
      quote do
        assert_received {:emote, {_, _, message}}
        assert Regex.match?(~r(#{unquote(emote)})i, message.message)
      end
    end

    defmacro assert_enter(event) do
      quote do
        assert_received {:enter, unquote(event)}
      end
    end

    defmacro refute_enter() do
      quote do
        refute_received {:enter, _}
      end
    end

    defmacro assert_leave(event) do
      quote do
        assert_received {:leave, unquote(event)}
      end
    end

    defmacro refute_leave() do
      quote do
        refute_received {:leave, _}
      end
    end

    defmacro assert_notify(event) do
      quote do
        assert_received {:notify, {_, _, unquote(event)}}
      end
    end

    defmacro assert_say(say) do
      quote do
        assert_received {:say, {_, _, message}}
        assert Regex.match?(~r(#{unquote(say)})i, message.message)
      end
    end

    defmacro refute_say() do
      quote do
        refute_receive {:say, _}, 50
      end
    end
  end
end
