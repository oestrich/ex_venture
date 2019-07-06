defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Command.AFK
  alias Game.Door
  alias Game.DoorLock
  alias Game.Format.Proficiencies, as: FormatProficiencies
  alias Game.Player
  alias Game.Proficiency
  alias Game.Proficiencies
  alias Game.Quest
  alias Game.Session.GMCP
  alias Metrics.CharacterInstrumenter

  @must_be_alive true

  commands(
    [
      "move",
      {"north", ["n"]},
      {"south", ["s"]},
      {"east", ["e"]},
      {"west", ["w"]},
      {"up", ["u"]},
      {"down", ["d"]},
      {"north west", ["nw"]},
      {"north east", ["ne"]},
      {"south west", ["sw"]},
      {"south east", ["se"]},
      "in",
      "out",
      "open",
      "close",
      "lock",
      "unlock"
    ],
    parse: false
  )

  @impl Game.Command
  def help(:topic), do: "Move"
  def help(:short), do: "Move in a direction"

  def help(:full) do
    """
    Move around rooms. You can move where you see an exit when looking.

    Example:
    [ ] > {command}move west{/command}
    [ ] > {command}west{/command}
    [ ] > {command}w{/command}

    Sometimes doors will be present between rooms. You will automatically open doors
    if they are closed and you move in their direction. You can open and close them
    manually as well.

    Example:
    [ ] > {command}open west{/command}
    [ ] > {command}close west{/command}

    If a door is locked, you can unlock it. Some locks require keys. You don't have to
    be holding the key, but it does have to be either wielded or in your inventory.

    Example:
    [ ] > {command}unlock west{/command}
    [ ] > {command}lock west{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments
  """
  @spec parse(command :: String.t()) :: {atom}
  def parse(commnd)
  def parse("move " <> direction), do: parse(direction)
  def parse("north"), do: {:move, "north"}
  def parse("n"), do: {:move, "north"}
  def parse("east"), do: {:move, "east"}
  def parse("e"), do: {:move, "east"}
  def parse("south"), do: {:move, "south"}
  def parse("s"), do: {:move, "south"}
  def parse("west"), do: {:move, "west"}
  def parse("w"), do: {:move, "west"}
  def parse("up"), do: {:move, "up"}
  def parse("u"), do: {:move, "up"}
  def parse("down"), do: {:move, "down"}
  def parse("d"), do: {:move, "down"}
  def parse("in"), do: {:move, "in"}
  def parse("out"), do: {:move, "out"}
  def parse("north west"), do: {:move, "north west"}
  def parse("nw"), do: {:move, "north west"}
  def parse("north east"), do: {:move, "north east"}
  def parse("ne"), do: {:move, "north east"}
  def parse("south west"), do: {:move, "south west"}
  def parse("sw"), do: {:move, "south west"}
  def parse("south east"), do: {:move, "south east"}
  def parse("se"), do: {:move, "south east"}

  def parse("open " <> direction) do
    case parse(direction) do
      {:move, direction} ->
        {:open, direction}

      _ ->
        {:error, :bad_parse, "open #{direction}"}
    end
  end

  def parse("close " <> direction) do
    case parse(direction) do
      {:move, direction} ->
        {:close, direction}

      _ ->
        {:error, :bad_parse, "close #{direction}"}
    end
  end

  def parse("lock " <> direction) do
    case parse(direction) do
      {:move, direction} ->
        {:lock, direction}

      _ ->
        {:error, :bad_parse, "lock #{direction}"}
    end
  end


  def parse("unlock " <> direction) do
    case parse(direction) do
      {:move, direction} ->
        {:unlock, direction}

      _ ->
        {:error, :bad_parse, "unlock #{direction}"}
    end
  end

  @impl Game.Command
  @doc """
  Move in the direction provided
  """
  def run(command, state)

  def run({:move, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      room_exit = %{finish_id: id} ->
        maybe_move_to(state, id, room_exit, direction)

      _ ->
        message = "Could not move #{direction}, no exit found."
        state |> Socket.echo(message)

        {:error, :no_exit}
    end
  end

  def run({:open, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} = door_info ->
        with {:ok, state} <- maybe_unlock_door(state, door_info) do
          state |> maybe_open_door(door_id) |> update_mini_map(room_id)
        else
          {:error, :door_locked} ->
            state

          error -> error
        end

      %{id: _exit_id} ->
        message = "There is no door #{direction}."
        state |> Socket.echo(message)

      _ ->
        message = "There is no exit #{direction}."
        state |> Socket.echo(message)
    end

    :ok
  end

  def run({:close, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} ->
        state |> maybe_close_door(door_id) |> update_mini_map(room_id)

      %{id: _exit_id} ->
        message = "There is no door #{direction}."
        state |> Socket.echo(message)

      _ ->
        message = "There is no exit #{direction}."
        state |> Socket.echo(message)
    end

    :ok
  end

  def run({:lock, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} = door_info ->
        case Door.get(door_id) do
          "open" ->
            message = "The #{direction} door is open."
            state |> Socket.echo(message)

          "closed" ->
            lock_closed_door(state, direction, door_info)
        end

      %{id: _exit_id} ->
        message = "There is no door #{direction}."
        state |> Socket.echo(message)

      _ ->
        message = "There is no exit #{direction}."
        state |> Socket.echo(message)
    end

    :ok
  end

  def run({:unlock, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} = door_info ->
        case Door.get(door_id) do
          "open" ->
            message = "The #{direction} door is open."
            state |> Socket.echo(message)

          "closed" ->
            unlock_closed_door(state, direction, door_info)
        end

      %{id: _exit_id} ->
        message = "There is no door #{direction}."
        state |> Socket.echo(message)

      _ ->
        message = "There is no exit #{direction}."
        state |> Socket.echo(message)
    end

    :ok
  end

  @doc """
  Lock a closed door. This assumes that the door is closed. Checks for key.
  """
  def lock_closed_door(state, direction, door_info) do
    case door_info do
      %{has_lock: true} ->
        if DoorLock.locked?(door_info.door_id) do
          message = "The #{direction} door is already locked."
          state |> Socket.echo(message)
        else
          case door_info do
            %{lock_key_id: key_id} when not is_nil(key_id) ->
              if has_lock_key?(state, key_id) do
                state |> lock_door(door_info.door_id)
                message = "You locked the #{direction} door."
                state |> Socket.echo(message)
              else
                message = "You don't have the right key to lock the #{direction} door."
                state |> Socket.echo(message)
              end

            _ ->
              message = "You don't have the right key to lock the #{direction} door."
              state |> Socket.echo(message)
          end
        end

      _ ->
        message = "There is no lock on the #{direction} door."
        state |> Socket.echo(message)
    end
  end

  @doc """
  Unlock a closed door. This assumes that the door is closed. Checks for key.
  """
  def unlock_closed_door(state, direction, door_info) do
    case door_info do
      %{has_lock: true} ->
        if DoorLock.unlocked?(door_info.door_id) do
          message = "The #{direction} door is already unlocked."
          state |> Socket.echo(message)
        else
          case door_info do
            %{lock_key_id: key_id} when not is_nil(key_id) ->
              if has_lock_key?(state, key_id) do
                state |> unlock_door(door_info.door_id)
                message = "You unlocked the #{direction} door."
                state |> Socket.echo(message)
              else
                message = "You don't have the right key to unlock the #{direction} door."
                state |> Socket.echo(message)
              end

            _ ->
              message = "You don't have the right key to unlock the #{direction} door."
              state |> Socket.echo(message)
          end
        end

      _ ->
        message = "There is no lock on the #{direction} door."
        state |> Socket.echo(message)
    end
  end

  @doc """
  Maybe move a player

  Checks for door state and if cooldowns are active
  """
  def maybe_move_to(state, room_id, room_exit, direction)

  def maybe_move_to(state, room_id, room_exit, direction) do
    with {:ok, state} <- maybe_unlock_door_before_move(state, room_exit),
         {:ok, state} <- maybe_open_door_before_move(state, room_exit),
         {:ok, state} <- check_cooldowns(state),
         {:ok, state} <- check_requirements(state, room_exit) do
      state |> move_to(room_id, {:leave, direction}, {:enter, Exit.opposite(direction)})
    else
      {:error, :cooldowns_active} ->
        state |> Socket.echo("You cannot move while a skill is cooling down.")

      {:error, :not_proficient, missing_requirements} ->
        state |> Socket.echo(FormatProficiencies.missing_requirements(direction, missing_requirements))

      {:error, :door_locked} ->
        state |> Socket.echo("You can't move through a locked door.")
    end
  end

  defp maybe_unlock_door_before_move(state, room_exit = %{has_door: true, has_lock: true, lock_key_id: lock_key_id}) when not is_nil(lock_key_id) and lock_key_id != "" do
    if Door.closed?(room_exit.door_id) && DoorLock.locked?(room_exit.door_id) do
      if has_lock_key?(state, lock_key_id) do
        state |> unlock_door(room_exit.door_id)
        state |> Socket.echo("You unlocked the door.")
        {:ok, state}
      else
        state |> Socket.echo("The door is locked.")
        {:error, :door_locked}
      end
    else
      {:ok, state}
    end
  end

  defp maybe_unlock_door_before_move(state, room_exit = %{has_door: true, has_lock: true}) do
    if Door.closed?(room_exit.door_id) && DoorLock.locked?(room_exit.door_id) do
      state |> Socket.echo("The door is locked.")
      {:error, :door_locked}
    else
      {:ok, state}
    end
  end

  defp maybe_unlock_door_before_move(state, _), do: {:ok, state}

  defp maybe_open_door_before_move(state, room_exit = %{has_door: true}) do
    case Door.get(room_exit.door_id) do
      "open" ->
        {:ok, state}

      "closed" ->
        Door.set(room_exit.door_id, "open")
        state |> Socket.echo("You opened the door.")
        {:ok, state}
    end
  end

  defp maybe_open_door_before_move(state, _), do: {:ok, state}

  defp check_cooldowns(state) do
    case Enum.empty?(Map.keys(state.skills)) do
      true ->
        {:ok, state}

      false ->
        {:error, :cooldowns_active}
    end
  end

  defp check_requirements(state, room_exit) do
    room_exit = Proficiencies.load_requirements(room_exit)

    case Proficiency.check_requirements_met(state.save, room_exit.requirements) do
      :ok ->
        {:ok, state}

      {:missing, requirements} ->
        {:error, :not_proficient, requirements}
    end
  end

  @doc """
  Move the player to a new room
  """
  def move_to(state, room_id, leave_reason, enter_reason) do
    state = move_to_instrumented(state, room_id, leave_reason, enter_reason)
    Game.Command.run(%Game.Command{module: Game.Command.Look, args: {}, system: true}, state)
    {:update, state}
  end

  defp move_to_instrumented(state, room_id, leave_reason, enter_reason) do
    %{save: save, character: character} = state

    CharacterInstrumenter.movement(:player, fn ->
      Environment.unlink(save.room_id)
      Environment.leave(save.room_id, character, leave_reason)

      clear_target(state)

      save = %{save | room_id: room_id}

      state |> maybe_welcome_back()

      state =
        state
        |> Player.update_save(save)
        |> Map.put(:target, nil)
        |> Map.put(:is_targeting, MapSet.new())
        |> Map.put(:is_afk, false)

      Environment.enter(room_id, character, enter_reason)
      Environment.link(room_id)

      Quest.track_progress(state.character, {:room, room_id})

      state
    end)
  end

  @doc """
  Unlock a door, if the door is locked
  """
  def maybe_unlock_door(state, _door_info = %{door_id: door_id, has_door: true, has_lock: true, lock_key_id: lock_key_id}) when not is_nil(lock_key_id) do
    if Door.closed?(door_id) && DoorLock.locked?(door_id) do
      if has_lock_key?(state, lock_key_id) do
        DoorLock.set(door_id, "unlocked")
        state |> Socket.echo("You unlocked the door.")
        {:ok, state}
      else
        state |> Socket.echo("The door is locked.")
        {:error, :door_locked}
      end
    else
      {:ok, state}
    end
  end

  def maybe_unlock_door(state, _door_info = %{door_id: door_id, has_door: true, has_lock: true}) do
    if Door.closed?(door_id) && DoorLock.locked?(door_id) do
      state |> Socket.echo("The door is locked.")
      {:error, :door_locked}
    else
      {:ok, state}
    end
  end

  def maybe_unlock_door(state, _), do: {:ok, state}

  @doc """
  Open a door, if the door was closed
  """
  def maybe_open_door(state, door_id) do
    case Door.get(door_id) do
      "closed" ->
        Door.set(door_id, "open")
        state |> Socket.echo("You opened the door.")

      _ ->
        state |> Socket.echo("The door was already open.")
    end

    state
  end

  @doc """
  Open a door, if the door was closed
  """
  def maybe_close_door(state, door_id) do
    case Door.get(door_id) do
      "open" ->
        Door.set(door_id, "closed")
        state |> Socket.echo("You closed the door.")

      _ ->
        state |> Socket.echo("The door was already closed.")
    end

    state
  end

  @doc """
  Lock a door.
  """
  def lock_door(state, door_id) do
    DoorLock.set(door_id, "locked")
    state
  end

  @doc """
  Unlock a door.
  """
  def unlock_door(state, door_id) do
    DoorLock.set(door_id, "unlocked")
    state
  end

  @doc """
  Open a door, if the door was closed
  """
  def maybe_welcome_back(state) do
    case state.is_afk do
      true ->
        state |> AFK.welcome_back()

      _ ->
        :ok
    end
  end

  @doc """
  Push out an update for the mini map after opening/closing doors
  """
  def update_mini_map(state, room_id) do
    {:ok, room} = Environment.look(room_id)
    mini_map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)
    state |> GMCP.map(mini_map)
    :ok
  end

  @doc """
  If the state has a target, send a GMCP message that the target was cleared
  """
  @spec clear_target(Session.t()) :: :ok
  def clear_target(state)

  def clear_target(state = %{target: target}) when target != nil do
    state |> GMCP.clear_target()
  end

  def clear_target(_state), do: :ok

  def has_lock_key?(%{save: %{wielding: wielding, items: items}}, lock_key_id) do
    Enum.any?(items, fn(item) -> item.id == lock_key_id end) ||
    Enum.any?(wielding, fn({_slot, item}) -> item.id == lock_key_id end)
  end

  def has_lock_key?(%{save: %{items: items}}, lock_key_id) do
    Enum.any?(items, fn(item) -> item.id == lock_key_id end)
  end

  def has_lock_key?(%{save: %{wielding: wielding}}, lock_key_id) do
    Enum.any?(wielding, fn({_slot, item}) -> item.id == lock_key_id end)
  end

  def has_lock_key?(_, _), do: false
end
