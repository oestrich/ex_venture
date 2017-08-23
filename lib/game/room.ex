defmodule Game.Room do
  @moduledoc """
  GenServer for each Room
  """

  use GenServer

  alias Data.Repo

  alias Game.Room.Actions
  alias Game.Room.Repo
  alias Game.Message
  alias Game.NPC
  alias Game.Session

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
  Pick up the item
  """
  @spec pick_up(id :: integer, item :: Item.t) :: :ok
  def pick_up(id, item) do
    GenServer.call(pid(id), {:pick_up, item})
  end

  @doc """
  Send a tick to the room
  """
  @spec tick(id :: pid) :: :ok
  def tick(pid) do
    GenServer.cast(pid, :tick)
  end

  def init(room) do
    {:ok, %{room: room, players: [], npcs: [], respawn: %{}}}
  end

  def handle_call(:look, _from, state = %{room: room, players: players, npcs: npcs}) do
    players = Enum.map(players, &(elem(&1, 2)))
    items = Game.Items.items(room.item_ids)
    {:reply, Map.merge(room, %{players: players, npcs: npcs, items: items}), state}
  end
  def handle_call({:pick_up, item}, _from, state = %{room: room}) do
    {room, return} = Actions.pick_up(room, item)
    {:reply, return, Map.put(state, :room, room)}
  end

  def handle_cast(:tick, state) do
    case Actions.tick(state) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:enter, player = {:user, _, user}}, state = %{players: players}) do
    players |> echo_to_players("{blue}#{user.name}{/blue} enters")
    {:noreply, Map.put(state, :players, [player | players])}
  end
  def handle_cast({:enter, {:npc, npc}}, state = %{npcs: npcs}) do
    {:noreply, Map.put(state, :npcs, [npc | npcs])}
  end

  def handle_cast({:leave, {:user, _, user}}, state = %{players: players}) do
    players = Enum.reject(players, &(elem(&1, 2).id == user.id))
    players |> echo_to_players("{blue}#{user.name}{/blue} leaves")
    {:noreply, Map.put(state, :players, players)}
  end
  def handle_cast({:leave, {:npc, npc}}, state = %{npcs: npcs}) do
    npcs = Enum.reject(npcs, &(&1.id == npc.id))
    npcs |> echo_to_npcs("{yellow}#{npc.name}{/yellow} leaves")
    {:noreply, Map.put(state, :npcs, npcs)}
  end

  def handle_cast({:say, sender, message}, state = %{players: players, npcs: npcs}) do
    players
    |> Enum.reject(&(elem(&1, 1) == sender)) # don't send to the sender
    |> echo_to_players(message.formatted)

    npcs |> echo_to_npcs(message)

    {:noreply, state}
  end

  defp echo_to_players(players, message) do
    Enum.each(players, fn ({:user, session, _user}) ->
      Session.echo(session, message)
    end)
  end

  @spec echo_to_npcs(npcs :: list, Message.t) :: :ok
  defp echo_to_npcs(npcs, message) do
    Enum.each(npcs, fn (npc) ->
      NPC.heard(npc.id, message)
    end)
  end
end
