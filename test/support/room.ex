defmodule Test.Game.Room do
  alias Data.Exit
  alias Game.Environment
  alias Test.Game.Room.FakeRoom

  def start_link() do
    Agent.start_link(fn () ->
      %{
        offline: false,
        room: _room(),
        rooms: %{},
      }
    end, name: __MODULE__)
  end

  def default_room(), do: _room()

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
    Process.put(:offline, true)
  end

  def set_room(room) do
    {:ok, pid} = FakeRoom.start_link(room)
    Process.put({:room, room.id}, pid)
  end

  def look(id) do
    case Process.get(:offline, false) do
      true ->
        {:error, :room_offline}

      false ->
        GenServer.call(Process.get({:room, id}), {:look})
    end
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

  def set_pick_up(room, response) do
    GenServer.call(Process.get({:room, room.id}), {:put, {:pick_up, response}})
  end

  def pick_up(id, item) do
    case Process.get(:offline, false) do
      true ->
        {:error, :room_offline}

      false ->
        GenServer.call(Process.get({:room, id}), {:pick_up, item})
    end
  end

  def set_pick_up_currency(room, response) do
    GenServer.call(Process.get({:room, room.id}), {:put, {:pick_up_currency, response}})
  end

  def pick_up_currency(id) do
    case Process.get(:offline, false) do
      true ->
        {:error, :room_offline}

      false ->
        GenServer.call(Process.get({:room, id}), {:pick_up_currency})
    end
  end

  def drop(id, who, item) do
    send(self(), {:drop, {id, who, item}})
  end

  def drop_currency(id, who, amount) do
    send(self(), {:drop, {id, who, {:currency, amount}}})
  end

  defmodule FakeRoom do
    use GenServer

    def start_link(room) do
      GenServer.start_link(__MODULE__, room)
    end

    @impl true
    def init(room) do
      {:ok, %{room: room, responses: %{}}}
    end

    @impl true
    def handle_call({:look}, _from, state) do
      {:reply, {:ok, state.room}, state}
    end

    def handle_call({:put, {field, response}}, _from, state) do
      responses = Map.put(state.responses, field, response)
      state = Map.put(state, :responses, responses)

      {:reply, :ok, state}
    end

    def handle_call({:pick_up, _item}, _from, state) do
      {:reply, state.responses[:pick_up], state}
    end

    def handle_call({:pick_up_currency}, _from, state) do
      {:reply, state.responses[:pick_up_currency], state}
    end
  end

  defmodule Helpers do
    @moduledoc """
    Helpers for dealing with rooms
    """

    alias Test.Game.Room

    def mark_room_offline() do
      Room.set_room(:offline)
    end

    def start_room(room = %Game.Environment.State.Room{}) do
      Room.set_room(room)
    end

    def start_room(room = %Game.Environment.State.Overworld{}) do
      Room.set_room(room)
    end

    def start_room(attributes) do
      attributes = Map.merge(Room.default_room(), attributes)
      Room.set_room(attributes)
    end

    def start_simple_room(attributes) do
      basic_room = %Game.Environment.State.Room{
        id: 1,
        name: "",
        description: "",
        players: [],
        shops: [],
        zone: %{id: 1, name: ""}
      }

      Room.set_room(Map.merge(basic_room, attributes))
    end

    def put_pick_up_response(room, response) do
      Room.set_pick_up(room, response)
    end

    def put_pick_up_currency_response(room, response) do
      Room.set_pick_up_currency(room, response)
    end

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
