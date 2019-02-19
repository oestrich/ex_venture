defmodule Game.NPC.Actions.CommandsMove do
  @moduledoc """
  Target a character
  """

  alias Data.Exit
  alias Game.Door
  alias Game.Environment
  alias Game.Events.RoomEntered
  alias Game.NPC
  alias Game.NPC.Events
  alias Metrics.CharacterInstrumenter

  @npc_reaction_time_ms Application.get_env(:ex_venture, :npc)[:reaction_time_ms]

  @doc """
  Move to a new room
  """
  def act(state, action) do
    spawner = state.npc_spawner

    with {:ok, :conscious} <- check_conscious(state),
         {:ok, :no_target} <- check_no_target(state),
         {:ok, starting_room} <- Environment.look(spawner.room_id),
         {:ok, old_room} <- Environment.look(state.room_id),
         {:ok, room_exit, new_room} <- select_new_room(old_room),
         {:ok, :allowed} <- check_movement_allowed(action, starting_room, room_exit, new_room) do
      move_room(state, old_room, new_room, room_exit.direction)
    else
      _ ->
        {:ok, state}
    end
  end

  @doc """
  Check that the NPC is conscious before moving

      iex> CommandsMove.check_conscious(%{npc: %{stats: %{health_points: 10}}})
      {:ok, :conscious}

      iex> CommandsMove.check_conscious(%{npc: %{stats: %{health_points: 0}}})
      {:error, :unconscious}
  """
  def check_conscious(state) do
    case state.npc.stats.health_points > 0 do
      true ->
        {:ok, :conscious}

      false ->
        {:error, :unconscious}
    end
  end

  @doc """
  Check that the NPC has no target before moving

      iex> CommandsMove.check_no_target(%{target: nil})
      {:ok, :no_target}

      iex> CommandsMove.check_no_target(%{target: {:player, %{}}})
      {:error, :target}
  """
  def check_no_target(state) do
    case is_nil(state.target) do
      true ->
        {:ok, :no_target}

      false ->
        {:error, :target}
    end
  end

  @doc """
  Select a random new room from the current room's exits
  """
  def select_new_room(room) do
    room_exit = Enum.random(room.exits)

    case Environment.look(room_exit.finish_id) do
      {:ok, room} ->
        {:ok, room_exit, room}

      error ->
        error
    end
  end

  @doc """
  Wraps `can_move?/4` with a tuple
  """
  def check_movement_allowed(action, old_room, room_exit, new_room) do
    case can_move?(action, old_room, room_exit, new_room) do
      true ->
        {:ok, :allowed}

      false ->
        {:error, :blocked}
    end
  end

  @doc """
  Check if the movement is allowed

  Checks for:
  - Same zone
  - Door is not present or is open
  - Under maximum movement allowed
  """
  def can_move?(action, old_room, room_exit, new_room) do
    no_door_or_open?(room_exit) && under_maximum_move?(action.options, old_room, new_room) &&
      new_room.zone_id == old_room.zone_id
  end

  @doc """
  Check if the exit has a door and if it does if it is open
  """
  def no_door_or_open?(room_exit) do
    !(room_exit.has_door && Door.closed?(room_exit.door_id))
  end

  @doc """
  Move to a new room
  """
  def move_room(state, old_room, new_room, direction) do
    CharacterInstrumenter.movement(:npc, fn ->
      Environment.unlink(old_room.id)
      Environment.leave(old_room.id, Events.npc(state), {:leave, direction})
      Environment.enter(new_room.id, Events.npc(state), {:enter, Exit.opposite(direction)})
      Environment.link(old_room.id)

      Enum.each(new_room.players, fn player ->
        event = %RoomEntered{character: {:player, player}}
        NPC.delay_notify(event, milliseconds: @npc_reaction_time_ms)
      end)
    end)

    {:ok, %{state | room_id: new_room.id}}
  end

  @doc """
  Determine if the new chosen room is too far to pick

      iex> old_room = %{x: 1, y: 1}
      iex> new_room = %{x: 1, y: 2}
      iex> CommandsMove.under_maximum_move?(%{max_distance: 2}, old_room, new_room)
      true

      iex> old_room = %{x: 1, y: 1}
      iex> new_room = %{x: 1, y: 4}
      iex> CommandsMove.under_maximum_move?(%{max_distance: 2}, old_room, new_room)
      false

      iex> old_room = %{x: 1, y: 1}
      iex> new_room = %{x: 1, y: 2}
      iex> CommandsMove.under_maximum_move?(%{}, old_room, new_room)
      false
  """
  def under_maximum_move?(option, old_room, new_room) do
    max_distance = Map.get(option, :max_distance, 0)

    abs(old_room.x - new_room.x) <= max_distance && abs(old_room.y - new_room.y) <= max_distance
  end
end
