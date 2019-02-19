defmodule Game.Room do
  @moduledoc """
  GenServer for each Room
  """

  use GenServer

  require Logger

  alias Data.Room
  alias Game.Environment
  alias Game.Events.RoomEntered
  alias Game.Events.RoomLeft
  alias Game.Features
  alias Game.Items
  alias Game.Room.Actions
  alias Game.Room.EventBus
  alias Game.Room.Repo, as: RoomRepo
  alias Game.Session
  alias Game.World.Master, as: WorldMaster
  alias Game.Zone

  @type t :: map

  @key :rooms

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: pid(room_id), id: room_id)
  end

  def pid(id) do
    {:global, {Game.Room, id}}
  end

  @doc """
  Get a simple version of the room
  """
  def name(id) do
    case Cachex.get(@key, id) do
      {:ok, room} when room != nil ->
        {:ok, room}

      _ ->
        case RoomRepo.get_name(id) do
          {:ok, room} ->
            Cachex.put(@key, room.id, room)
            {:ok, room}

          {:error, :unknown} ->
            {:error, :unknown}
        end
    end
  end

  @doc """
  Load all rooms in the database
  """
  @spec all() :: [map()]
  def all() do
    RoomRepo.all()
  end

  @doc """
  Load all rooms for a zone
  """
  @spec for_zone(integer()) :: [map()]
  def for_zone(zone_id) do
    RoomRepo.for_zone(zone_id)
  end

  @doc """
  Update a room's data
  """
  @spec update(integer(), Room.t()) :: :ok
  def update(id, room) do
    GenServer.cast(pid(id), {:update, room})
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  def init(room_id) do
    state = %{room: nil, players: [], npcs: [], respawn: %{}}
    {:ok, state, {:continue, {:load_room, room_id}}}
  end

  def handle_continue({:load_room, room_id}, state) do
    case RoomRepo.get(room_id) do
      nil ->
        Logger.error("No room could be found for ID #{room_id}", type: :room)
        {:stop, :normal, state}

      room ->
        room.zone_id |> Zone.room_online(room)
        WorldMaster.update_cache(@key, Map.take(room, [:id, :name]))
        Logger.info("Room online #{room.id}", type: :room)
        {:noreply, %{state | room: room}}
    end
  end

  def handle_call(:look, _from, state = %{room: room, players: players, npcs: npcs}) do
    global_features = room.feature_ids |> Features.features()
    features = room.features ++ global_features

    environment = %Environment.State.Room{
      id: room.id,
      zone_id: room.zone_id,
      zone: room.zone,
      name: room.name,
      description: room.description,
      currency: room.currency,
      items: room.items,
      features: features,
      listen: room.listen,
      x: room.x,
      y: room.y,
      map_layer: room.map_layer,
      ecology: room.ecology,
      shops: room.shops,
      exits: room.exits,
      players: players,
      npcs: npcs
    }

    {:reply, {:ok, environment}, state}
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
    WorldMaster.update_cache(@key, room)

    state = Map.put(state, :room, room)

    case Actions.maybe_respawn_items(state) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:enter, {:player, player}, reason}, state) do
    %{room: room, players: players} = state
    Logger.debug(fn -> "Player (#{player.id}) entered room (#{room.id})" end, type: :room)
    state = %{state | players: [player | players]}

    event = %RoomEntered{character: {:player, player}, reason: reason}
    handle_cast({:notify, {:player, player}, event}, state)
  end

  def handle_cast({:enter, {:npc, npc}, reason}, state) do
    %{room: room, npcs: npcs} = state
    Logger.debug(fn -> "NPC (#{npc.id}) entered room (#{room.id})" end, type: :room)
    state = %{state | npcs: [npc | npcs]}

    event = %RoomEntered{character: {:npc, npc}, reason: reason}
    handle_cast({:notify, {:npc, npc}, event}, state)
  end

  def handle_cast({:leave, {:player, player}, reason}, state) do
    %{room: room, players: players} = state
    Logger.debug(fn -> "Player (#{player.id}) left room (#{room.id})" end, type: :room)
    players = Enum.reject(players, &(&1.id == player.id))
    state = %{state | players: players}

    event = %RoomLeft{character: {:player, player}, reason: reason}
    handle_cast({:notify, {:player, player}, event}, state)
  end

  def handle_cast({:leave, {:npc, npc}, reason}, state) do
    %{room: room, npcs: npcs} = state
    Logger.debug(fn -> "NPC (#{npc.id}) left room (#{room.id})" end, type: :room)
    npcs = Enum.reject(npcs, &(&1.id == npc.id))
    state = %{state | npcs: npcs}

    event = %RoomLeft{character: {:npc, npc}, reason: reason}
    handle_cast({:notify, {:npc, npc}, event}, state)
  end

  def handle_cast({:notify, actor, event}, state) do
    EventBus.notify(state.room.id, actor, event, state.players, state.npcs)

    {:noreply, state}
  end

  def handle_cast({:update_character, {:player, player}}, state = %{players: players}) do
    case Enum.member?(Enum.map(players, & &1.id), player.id) do
      true ->
        players = players |> Enum.reject(&(&1.id == player.id))
        players = [player | players]
        {:noreply, Map.put(state, :players, players)}

      false ->
        {:noreply, state}
    end
  end

  def handle_cast({:update_character, {:npc, npc}}, state = %{npcs: npcs}) do
    case Enum.find(npcs, &(&1.id == npc.id)) do
      nil ->
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

  def handle_info({:respawn, item_id}, state) do
    case Actions.respawn_item(state, item_id) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  defp inform_players(players, action) do
    Enum.each(players, fn player ->
      Session.notify(player, action)
    end)
  end
end
