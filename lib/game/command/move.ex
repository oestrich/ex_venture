defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Command.AFK
  alias Game.Door
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
      "close"
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

    Open and close doors.

    Example:
    [ ] > {command}open west{/command}
    [ ] > {command}close west{/command}
    """
  end

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
      {:move, direction} -> {:open, direction}
      _ -> {:error, :bad_parse, "open #{direction}"}
    end
  end

  def parse("close " <> direction) do
    case parse(direction) do
      {:move, direction} -> {:close, direction}
      _ -> {:error, :bad_parse, "close #{direction}"}
    end
  end

  @impl Game.Command
  @doc """
  Move in the direction provided
  """
  def run(command, state)

  def run({:move, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      room_exit = %{finish_id: id} ->
        maybe_move_to(state, id, room_exit, direction)

      _ ->
        {:error, :no_exit}
    end
  end

  def run({:open, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} ->
        state |> maybe_open_door(door_id) |> update_mini_map(room_id)

      %{id: _exit_id} ->
        state.socket |> @socket.echo(gettext("There is no door %{direction}.", direction: direction))

      _ ->
        state.socket |> @socket.echo(gettext("There is no exit %{direction}.", direction: direction))
    end

    :ok
  end

  def run({:close, direction}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{door_id: door_id, has_door: true} ->
        state |> maybe_close_door(door_id) |> update_mini_map(room_id)

      %{id: _exit_id} ->
        state.socket |> @socket.echo(gettext("There is no door %{direction}.", direction: direction))

      _ ->
        state.socket |> @socket.echo(gettext("There is no exit %{direction}.", direction: direction))
    end

    :ok
  end

  @doc """
  Maybe move a player

  They require at least 1 movement point to proceed
  """
  def maybe_move_to(state, room_id, room_exit, direction)

  def maybe_move_to(state = %{socket: socket}, room_id, room_exit = %{has_door: true}, direction) do
    case Door.get(room_exit.door_id) do
      "open" ->
        maybe_move_to(state, room_id, %{}, direction)

      "closed" ->
        Door.set(room_exit.door_id, "open")
        socket |> @socket.echo(gettext("You opened the door."))
        maybe_move_to(state, room_id, room_exit, direction)
    end
  end

  def maybe_move_to(state, room_id, _, direction) do
    with {:ok, state} <- check_cooldowns(state) do
      state |> move_to(room_id, {:leave, direction}, {:enter, Exit.opposite(direction)})
    else
      {:error, :cooldowns_active} ->
        state.socket |> @socket.echo(gettext("You cannot move while a skill is cooling down."))
    end
  end

  defp check_cooldowns(state) do
    case Enum.empty?(Map.keys(state.skills)) do
      true ->
        {:ok, state}

      false ->
        {:error, :cooldowns_active}
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
    %{save: save, user: user} = state

    CharacterInstrumenter.movement(:player, fn ->
      @environment.unlink(save.room_id)
      @environment.leave(save.room_id, {:player, user}, leave_reason)

      clear_target(state)

      save = %{save | room_id: room_id}

      state |> maybe_welcome_back()

      state =
        state
        |> Map.put(:save, save)
        |> Map.put(:target, nil)
        |> Map.put(:is_targeting, MapSet.new())
        |> Map.put(:is_afk, false)

      @environment.enter(room_id, {:player, user}, enter_reason)
      @environment.link(room_id)

      Quest.track_progress(user, {:room, room_id})

      state
    end)
  end

  @doc """
  Open a door, if the door was closed
  """
  def maybe_open_door(state, door_id) do
    case Door.get(door_id) do
      "closed" ->
        Door.set(door_id, "open")
        state.socket |> @socket.echo(gettext("You opened the door."))

      _ ->
        state.socket |> @socket.echo(gettext("The door was already open."))
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
        state.socket |> @socket.echo(gettext("You closed the door."))

      _ ->
        state.socket |> @socket.echo(gettext("The door was already closed."))
    end

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
    {:ok, room} = @environment.look(room_id)
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
end
