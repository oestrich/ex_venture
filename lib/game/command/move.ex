defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Door
  alias Game.Quest
  alias Game.Session.GMCP

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
  def parse("north"), do: {:north}
  def parse("n"), do: {:north}
  def parse("east"), do: {:east}
  def parse("e"), do: {:east}
  def parse("south"), do: {:south}
  def parse("s"), do: {:south}
  def parse("west"), do: {:west}
  def parse("w"), do: {:west}
  def parse("up"), do: {:up}
  def parse("u"), do: {:up}
  def parse("down"), do: {:down}
  def parse("d"), do: {:down}
  def parse("in"), do: {:in}
  def parse("out"), do: {:out}

  def parse("open " <> direction) do
    case parse(direction) do
      {direction} -> {:open, direction}
      _ -> {:error, :bad_parse, "open #{direction}"}
    end
  end

  def parse("close " <> direction) do
    case parse(direction) do
      {direction} -> {:close, direction}
      _ -> {:error, :bad_parse, "close #{direction}"}
    end
  end

  @impl Game.Command
  @doc """
  Move in the direction provided
  """
  def run(command, state)

  def run({:east}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:east) do
      room_exit = %{east_id: id} -> maybe_move_to(state, id, room_exit, :east)
      _ -> {:error, :no_exit}
    end
  end

  def run({:north}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:north) do
      room_exit = %{north_id: id} -> maybe_move_to(state, id, room_exit, :north)
      _ -> {:error, :no_exit}
    end
  end

  def run({:south}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:south) do
      room_exit = %{south_id: id} -> maybe_move_to(state, id, room_exit, :south)
      _ -> {:error, :no_exit}
    end
  end

  def run({:west}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:west) do
      room_exit = %{west_id: id} -> maybe_move_to(state, id, room_exit, :west)
      _ -> {:error, :no_exit}
    end
  end

  def run({:up}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:up) do
      room_exit = %{up_id: id} -> maybe_move_to(state, id, room_exit, :up)
      _ -> {:error, :no_exit}
    end
  end

  def run({:down}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:down) do
      room_exit = %{down_id: id} -> maybe_move_to(state, id, room_exit, :down)
      _ -> {:error, :no_exit}
    end
  end

  def run({:in}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:in) do
      room_exit = %{in_id: id} -> maybe_move_to(state, id, room_exit, :in)
      _ -> {:error, :no_exit}
    end
  end

  def run({:out}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(:out) do
      room_exit = %{out_id: id} -> maybe_move_to(state, id, room_exit, :out)
      _ -> {:error, :no_exit}
    end
  end

  def run({:open, direction}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{id: exit_id, has_door: true} ->
        state |> maybe_open_door(exit_id) |> update_mini_map(room_id)

      %{id: _exit_id} ->
        state.socket |> @socket.echo("There is no door #{direction}.")

      _ ->
        state.socket |> @socket.echo("There is no exit #{direction}.")
    end

    :ok
  end

  def run({:close, direction}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case room |> Exit.exit_to(direction) do
      %{id: exit_id, has_door: true} ->
        state |> maybe_close_door(exit_id) |> update_mini_map(room_id)

      %{id: _exit_id} ->
        state.socket |> @socket.echo("There is no door #{direction}.")

      _ ->
        state.socket |> @socket.echo("There is no exit #{direction}.")
    end

    :ok
  end

  @doc """
  Maybe move a player

  They require at least 1 movement point to proceed
  """
  def maybe_move_to(state, room_id, room_exit, direction)

  def maybe_move_to(
        state = %{socket: socket},
        room_id,
        room_exit = %{id: exit_id, has_door: true},
        direction
      ) do

    case Door.get(exit_id) do
      "open" ->
        maybe_move_to(state, room_id, %{}, direction)

      "closed" ->
        Door.set(exit_id, "open")
        socket |> @socket.echo("You opened the door.")
        maybe_move_to(state, room_id, room_exit, direction)
    end
  end

  def maybe_move_to(state = %{save: %{stats: stats}}, room_id, _, direction) do
    case stats.move_points > 0 do
      true ->
        stats = %{stats | move_points: stats.move_points - 1}
        save = %{state.save | stats: stats}

        state
        |> Map.put(:save, save)
        |> move_to(room_id, {:leave, direction}, {:enter, Exit.opposite(direction)})

      false ->
        state.socket |> @socket.echo("You have no movement points to move in that direction.")
        {:error, :no_movement}
    end
  end

  @doc """
  Move the player to a new room
  """
  def move_to(
        state = %{save: save, user: user},
        room_id,
        leave_reason,
        enter_reason
      ) do

    @room.unlink(save.room_id)
    @room.leave(save.room_id, {:user, user}, leave_reason)

    clear_target(state)

    save = %{save | room_id: room_id}

    state =
      state
      |> Map.put(:save, save)
      |> Map.put(:target, nil)
      |> Map.put(:is_targeting, MapSet.new())

    @room.enter(room_id, {:user, user}, enter_reason)
    @room.link(room_id)

    Quest.track_progress(user, {:room, room_id})

    Game.Command.run(%Game.Command{module: Game.Command.Look, args: {}, system: true}, state)
    {:update, state}
  end

  @doc """
  Open a door, if the door was closed
  """
  def maybe_open_door(state, exit_id) do
    case Door.get(exit_id) do
      "closed" ->
        Door.set(exit_id, "open")
        state.socket |> @socket.echo("You opened the door.")

      _ ->
        state.socket |> @socket.echo("The door was already open.")
    end

    state
  end

  @doc """
  Open a door, if the door was closed
  """
  def maybe_close_door(state, exit_id) do
    case Door.get(exit_id) do
      "open" ->
        Door.set(exit_id, "closed")
        state.socket |> @socket.echo("You closed the door.")

      _ ->
        state.socket |> @socket.echo("The door was already closed.")
    end

    state
  end

  @doc """
  Push out an update for the mini map after opening/closing doors
  """
  def update_mini_map(state, room_id) do
    room = @room.look(room_id)
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
