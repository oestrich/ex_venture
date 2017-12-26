defmodule Game.Room do
  @moduledoc """
  GenServer for each Room
  """

  use GenServer

  require Logger

  alias Data.Room
  alias Game.Format
  alias Game.Items
  alias Game.Message
  alias Game.NPC
  alias Game.Room.Actions
  alias Game.Room.Repo
  alias Game.Session
  alias Game.Zone

  @type t :: map

  defmacro __using__(_opts) do
    quote do
      @room Application.get_env(:ex_venture, :game)[:room]
    end
  end

  def start_link(room) do
    GenServer.start_link(__MODULE__, room, name: pid(room.id))
  end

  def pid(id) do
    {:via, Registry, {Game.Room.Registry, id}}
  end

  @doc """
  Load all rooms in the database
  """
  @spec all() :: [map]
  def all() do
    Repo.all
  end

  @doc """
  Load all rooms for a zone
  """
  @spec for_zone(zone_id :: integer) :: [map]
  def for_zone(zone_id) do
    Repo.for_zone(zone_id)
  end

  @doc """
  Look around the room

  Fetches current room
  """
  def look(id) do
    GenServer.call(pid(id), :look)
  end

  @doc """
  Enter a room
  """
  @spec enter(id :: integer, {:user, session :: pid, user :: map}) :: :ok
  @spec enter(id :: integer, {:npc, npc :: map}) :: :ok
  def enter(id, {:user, session, user}) do
    GenServer.cast(pid(id), {:enter, {:user, session, user}})
  end
  def enter(id, {:npc, npc}) do
    GenServer.cast(pid(id), {:enter, {:npc, npc}})
  end

  @doc """
  Leave a room
  """
  @spec leave(id :: integer, user :: {:user, session :: pid, user :: map}) :: :ok
  def leave(id, {:user, session, user}) do
    GenServer.cast(pid(id), {:leave, {:user, session, user}})
  end
  def leave(id, {:npc, npc}) do
    GenServer.cast(pid(id), {:leave, {:npc, npc}})
  end

  @doc """
  Say to the players in the room
  """
  @spec say(id :: integer, sender :: pid, message :: Message.t) :: :ok
  def say(id, sender, message) do
    GenServer.cast(pid(id), {:say, sender, message})
  end

  @doc """
  Emote to the players in the room
  """
  @spec emote(id :: integer, sender :: pid, message :: Message.t) :: :ok
  def emote(id, sender, message) do
    GenServer.cast(pid(id), {:emote, sender, message})
  end

  @doc """
  Update the character after a stats change
  """
  @spec update_character(id :: integer, character :: tuple) :: :ok
  def update_character(id, character) do
    GenServer.cast(pid(id), {:update_character, character})
  end

  @doc """
  Pick up the item
  """
  @spec pick_up(id :: integer, item :: Item.t) :: :ok
  def pick_up(id, item) do
    GenServer.call(pid(id), {:pick_up, item})
  end

  @doc """
  Pick up currency
  """
  @spec pick_up_currency(id :: integer) :: :ok
  def pick_up_currency(id) do
    GenServer.call(pid(id), :pick_up_currency)
  end

  @doc """
  Drop an item into a room
  """
  @spec drop(id :: integer, who :: {atom, map}, item :: Item.t) :: :ok
  def drop(id, who, item) do
    GenServer.cast(pid(id), {:drop, who, item})
  end

  @doc """
  Drop currency into a room
  """
  @spec drop_currency(id :: integer, who :: {atom, map}, current :: integer) :: :ok
  def drop_currency(id, who, currency) do
    GenServer.cast(pid(id), {:drop_currency, who, currency})
  end

  @doc """
  Send a tick to the room
  """
  @spec tick(id :: integer, time :: DateTime.t) :: :ok
  def tick(id, _time) do
    GenServer.cast(pid(id), :tick)
  end

  @doc """
  Update a room's data
  """
  @spec update(id :: integer, room :: Room.t) :: :ok
  def update(id, room) do
    GenServer.cast(pid(id), {:update, room})
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  def init(room) do
    Logger.info("Room online #{room.id}", type: :room)
    room.zone_id |> Zone.room_online(room)
    {:ok, %{room: room, players: [], npcs: [], respawn: %{}}}
  end

  def handle_call(:look, _from, state = %{room: room, players: players, npcs: npcs}) do
    players = Enum.map(players, &(elem(&1, 2)))
    {:reply, Map.merge(room, %{players: players, npcs: npcs}), state}
  end

  def handle_call({:pick_up, item}, _from, state = %{room: room}) do
    {room, return} = Actions.pick_up(room, item)
    {:reply, return, Map.put(state, :room, room)}
  end

  def handle_call(:pick_up_currency, _from, state = %{room: room}) do
    {room, return} = Actions.pick_up_currency(room)
    {:reply, return, Map.put(state, :room, room)}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update, room}, state) do
    Logger.info("Room updated #{room.id}", type: :room)
    room.zone_id |> Zone.update_room(room)
    {:noreply, Map.put(state, :room, room)}
  end

  def handle_cast(:tick, state) do
    case Actions.tick(state) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:enter, player = {:user, _, user}}, state = %{room: room, players: players, npcs: npcs}) do
    Logger.info("Player (#{user.id}) entered room (#{room.id})", type: :room)
    players |> inform_players({"room/entered", {:user, user}})
    npcs |> inform_npcs({"room/entered", player})
    {:noreply, Map.put(state, :players, [player | players])}
  end
  def handle_cast({:enter, {:npc, npc}}, state = %{room: room, npcs: npcs, players: players}) do
    Logger.info("NPC (#{npc.id}) entered room (#{room.id})", type: :room)
    players |> inform_players({"room/entered", {:npc, npc}})
    npcs |> inform_npcs({"room/entered", {:npc, npc}})
    {:noreply, Map.put(state, :npcs, [npc | npcs])}
  end

  def handle_cast({:leave, {:user, _, user}}, state = %{room: room, players: players, npcs: npcs}) do
    Logger.info("Player (#{user.id}) left room (#{room.id})", type: :room)
    players = Enum.reject(players, &(elem(&1, 2).id == user.id))
    players |> inform_players({"room/leave", {:user, user}})
    npcs |> inform_npcs({"room/leave", {:user, user}})
    {:noreply, Map.put(state, :players, players)}
  end
  def handle_cast({:leave, {:npc, npc}}, state = %{room: room, players: players, npcs: npcs}) do
    Logger.info("NPC (#{npc.id}) left room (#{room.id})", type: :room)
    npcs = Enum.reject(npcs, &(&1.id == npc.id))
    players |> inform_players({"room/leave", {:npc, npc}})
    npcs |> inform_npcs({"room/leave", {:npc, npc}})
    {:noreply, Map.put(state, :npcs, npcs)}
  end

  def handle_cast({:say, sender, message}, state = %{players: players, npcs: npcs}) do
    players
    |> Enum.reject(&(elem(&1, 1) == sender)) # don't send to the sender
    |> echo_to_players(message.formatted)

    npcs |> inform_npcs({"room/heard", message})

    {:noreply, state}
  end

  def handle_cast({:emote, sender, message}, state = %{players: players, npcs: npcs}) do
    players
    |> Enum.reject(&(elem(&1, 1) == sender)) # don't send to the sender
    |> echo_to_players(message.formatted)

    npcs |> inform_npcs({"room/heard", message})

    {:noreply, state}
  end

  def handle_cast({:update_character, player = {:user, session, _user}}, state = %{players: players}) do
    case Enum.member?(Enum.map(players, &(elem(&1, 1))), session) do
      true ->
        players = players |> Enum.reject(&(elem(&1, 1) == session))
        players = [player | players]
        {:noreply, Map.put(state, :players, players)}
      false ->
        {:noreply, state}
    end
  end
  def handle_cast({:update_character, {:npc, npc}}, state = %{npcs: npcs}) do
    case Enum.find(npcs, &(&1.id == npc.id)) do
      nil ->
        GenServer.cast(self(), {:enter, {:npc, npc}})
        {:noreply, state}
      _npc ->
        npcs = npcs |> Enum.reject(&(&1.id == npc.id))
        npcs = [npc | npcs]
        {:noreply, Map.put(state, :npcs, npcs)}
    end
  end

  def handle_cast({:drop, who, instance}, state = %{room: room, players: players}) do
    case Actions.drop(room, instance) do
      {:ok, room} ->
        item = Items.item(instance)
        Logger.info("Character (#{elem(who, 0)}, #{elem(who, 1).id}) dropped item (#{item.id})", type: :room)
        players |> echo_to_players(Format.dropped(who, item))
        {:noreply, Map.put(state, :room, room)}
      _ -> {:noreply, state}
    end
  end

  def handle_cast({:drop_currency, who, amount}, state = %{room: room, players: players}) do
    case Actions.drop_currency(room, amount) do
      {:ok, room} ->
        Logger.info("Character (#{elem(who, 0)}, #{elem(who, 1).id}) dropped #{amount} currency", type: :room)
        players |> echo_to_players(who, Format.dropped(who, {:currency, amount}))
        {:noreply, Map.put(state, :room, room)}
      _ -> {:noreply, state}
    end
  end

  defp echo_to_players(players, {:user, user}, message) do
    players
    |> Enum.reject(fn ({_, _, player}) -> player.id == user.id end)
    |> echo_to_players(message)
  end
  defp echo_to_players(players, _, message) do
    echo_to_players(players, message)
  end

  defp echo_to_players(players, message) do
    Enum.each(players, fn ({:user, session, _user}) ->
      Session.echo(session, message)
    end)
  end

  defp inform_players(players, action) do
    Enum.each(players, fn ({:user, session, _user}) ->
      Session.notify(session, action)
    end)
  end

  @spec inform_npcs(npcs :: list, action :: tuple) :: :ok
  defp inform_npcs(npcs, action) do
    Enum.each(npcs, fn (npc) ->
      NPC.notify(npc.id, action)
    end)
  end
end
