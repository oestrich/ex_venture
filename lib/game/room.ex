defmodule Game.Room do
  @moduledoc """
  GenServer for each Room
  """

  use GenServer

  require Logger

  alias Data.Room
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

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: pid(room_id))
  end

  def pid(id) do
    {:via, Registry, {Game.Room.Registry, id}}
  end

  @doc """
  Load all rooms in the database
  """
  @spec all() :: [map()]
  def all() do
    Repo.all()
  end

  @doc """
  Load all rooms for a zone
  """
  @spec for_zone(integer()) :: [map()]
  def for_zone(zone_id) do
    Repo.for_zone(zone_id)
  end

  @doc """
  Look around the room

  Fetches current room
  """
  @spec look(integer()) :: Room.t()
  def look(id) do
    GenServer.call(pid(id), :look)
  end

  @doc """
  Enter a room

  Valid enter reasons: `:enter`, `:respawn`
  """
  @spec enter(integer(), Character.t(), atom()) :: :ok
  def enter(id, character, reason \\ :enter)

  def enter(id, character, reason) do
    GenServer.cast(pid(id), {:enter, character, reason})
  end

  @doc """
  Leave a room

  Valid leave reasons: `:leave`, `:death`
  """
  @spec leave(integer(), Character.t(), atom()) :: :ok
  def leave(id, character, reason \\ :leave)

  def leave(id, character, reason) do
    GenServer.cast(pid(id), {:leave, character, reason})
  end

  @doc """
  Notify characters in a room of an event
  """
  @spec notify(integer(), Character.t(), tuple()) :: :ok
  def notify(id, character, event)

  def notify(id, character, event) do
    GenServer.cast(pid(id), {:notify, character, event})
  end

  @doc """
  Say to the players in the room
  """
  @spec say(integer(), pid(), Message.t()) :: :ok
  def say(id, sender, message) do
    GenServer.cast(pid(id), {:say, sender, message})
  end

  @doc """
  Emote to the players in the room
  """
  @spec emote(integer(), pid(), Message.t()) :: :ok
  def emote(id, sender, message) do
    GenServer.cast(pid(id), {:emote, sender, message})
  end

  @doc """
  Update the character after a stats change
  """
  @spec update_character(integer(), tuple()) :: :ok
  def update_character(id, character) do
    GenServer.cast(pid(id), {:update_character, character})
  end

  @doc """
  Pick up the item
  """
  @spec pick_up(integer(), Item.t()) :: :ok
  def pick_up(id, item) do
    GenServer.call(pid(id), {:pick_up, item})
  end

  @doc """
  Pick up currency
  """
  @spec pick_up_currency(integer()) :: :ok
  def pick_up_currency(id) do
    GenServer.call(pid(id), :pick_up_currency)
  end

  @doc """
  Drop an item into a room
  """
  @spec drop(integer(), Character.t(), Item.t()) :: :ok
  def drop(id, who, item) do
    GenServer.cast(pid(id), {:drop, who, item})
  end

  @doc """
  Drop currency into a room
  """
  @spec drop_currency(integer(), Character.t(), integer()) :: :ok
  def drop_currency(id, who, currency) do
    GenServer.cast(pid(id), {:drop_currency, who, currency})
  end

  @doc """
  Update a room's data
  """
  @spec update(integer(), Room.t()) :: :ok
  def update(id, room) do
    GenServer.cast(pid(id), {:update, room})
  end

  @doc """
  Crash a room process with an unmatched cast

  There should always remain no matching clause for this cast
  """
  def crash(id) do
    GenServer.cast(pid(id), :crash)
  end

  @doc """
  Link the current process against the room's pid, finds by id
  """
  def link(id) do
    case Registry.lookup(Game.Room.Registry, id) do
      [{pid, _}] ->
        Process.link(pid)

      _ ->
        :ok
    end
  end

  @doc """
  Unlink the current process against the room's pid, finds by id
  """
  def unlink(id) do
    case Registry.lookup(Game.Room.Registry, id) do
      [{pid, _}] ->
        Process.unlink(pid)

      _ ->
        :ok
    end
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  def init(room_id) do
    send(self(), {:load_room, room_id})
    {:ok, %{room: nil, players: [], npcs: [], respawn: %{}}}
  end

  def handle_call(:look, _from, state = %{room: room, players: players, npcs: npcs}) do
    {:reply, Map.merge(room, %{players: players, npcs: npcs}), state}
  end

  def handle_call({:pick_up, item}, _from, state = %{room: room}) do
    {room, return} = Actions.pick_up(room, item)

    state = %{state | room: room}

    case Actions.maybe_respawn_items(state) do
      :ok ->
        {:reply, return, state}

      {:update, state} ->
        {:reply, return, state}
    end
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

  def handle_cast({:enter, {:user, user}, reason}, state) do
    %{room: room, players: players, npcs: npcs} = state

    Logger.debug(fn -> "Player (#{user.id}) entered room (#{room.id})" end, type: :room)

    players |> inform_players({"room/entered", {{:user, user}, reason}})
    npcs |> inform_npcs({"room/entered", {{:user, user}, reason}})

    {:noreply, Map.put(state, :players, [user | players])}
  end

  def handle_cast({:enter, {:npc, npc}, reason}, state) do
    %{room: room, players: players, npcs: npcs} = state

    Logger.debug(fn -> "NPC (#{npc.id}) entered room (#{room.id})" end, type: :room)

    players |> inform_players({"room/entered", {{:npc, npc}, reason}})
    npcs |> inform_npcs({"room/entered", {{:npc, npc}, reason}})

    {:noreply, Map.put(state, :npcs, [npc | npcs])}
  end

  def handle_cast({:leave, {:user, user}, reason}, state) do
    %{room: room, players: players} = state

    Logger.debug(fn -> "Player (#{user.id}) left room (#{room.id})" end, type: :room)
    players = Enum.reject(players, &(&1.id == user.id))
    state = %{state | players: players}

    handle_cast({:notify, {:user, user}, {"room/leave", {{:user, user}, reason}}}, state)
  end

  def handle_cast({:leave, {:npc, npc}, reason}, state) do
    %{room: room, npcs: npcs} = state

    Logger.debug(fn -> "NPC (#{npc.id}) left room (#{room.id})" end, type: :room)
    npcs = Enum.reject(npcs, &(&1.id == npc.id))
    state = %{state | npcs: npcs}

    handle_cast({:notify, {:npc, npc}, {"room/leave", {{:npc, npc}, reason}}}, state)
  end

  def handle_cast({:notify, {:user, sender}, event}, state = %{players: players, npcs: npcs}) do
    # don't send to the sender
    players
    |> Enum.reject(&(&1.id == sender.id))
    |> inform_players(event)

    npcs |> inform_npcs(event)

    {:noreply, state}
  end

  def handle_cast({:notify, {:npc, sender}, event}, state = %{players: players, npcs: npcs}) do
    players |> inform_players(event)

    # don't send to the sender
    npcs
    |> Enum.reject(&(&1.id == sender.id))
    |> inform_npcs(event)

    {:noreply, state}
  end

  def handle_cast({:say, sender, message}, state) do
    handle_cast({:notify, sender, {"room/heard", message}}, state)
  end

  def handle_cast({:emote, sender, message}, state) do
    handle_cast({:notify, sender, {"room/heard", message}}, state)
  end

  def handle_cast({:update_character, {:user, user}}, state = %{players: players}) do
    case Enum.member?(Enum.map(players, & &1.id), user.id) do
      true ->
        players = players |> Enum.reject(&(&1.id == user.id))
        players = [user | players]
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

        Logger.info(
          "Character (#{elem(who, 0)}, #{elem(who, 1).id}) dropped item (#{item.id})",
          type: :room
        )

        players |> inform_players({"item/dropped", who, item})
        {:noreply, Map.put(state, :room, room)}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:drop_currency, who, amount}, state = %{room: room, players: players}) do
    case Actions.drop_currency(room, amount) do
      {:ok, room} ->
        Logger.info(
          "Character (#{elem(who, 0)}, #{elem(who, 1).id}) dropped #{amount} currency",
          type: :room
        )

        players |> inform_players({"currency/dropped", who, amount})
        {:noreply, Map.put(state, :room, room)}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:load_room, room_id}, state) do
    case Repo.get(room_id) do
      nil ->
        Logger.error("No room could be found for ID #{room_id}", type: :room)
        {:stop, :normal, state}

      room ->
        room.zone_id |> Zone.room_online(room)
        Logger.info("Room online #{room.id}", type: :room)
        {:noreply, %{state | room: room}}
    end
  end

  def handle_info({:respawn, item_id}, state) do
    case Actions.respawn_item(state, item_id) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  defp inform_players(players, action) do
    Enum.each(players, fn user ->
      Session.notify(user, action)
    end)
  end

  @spec inform_npcs(npcs :: list, action :: tuple) :: :ok
  defp inform_npcs(npcs, action) do
    Enum.each(npcs, fn npc ->
      NPC.notify(npc.id, action)
    end)
  end
end
