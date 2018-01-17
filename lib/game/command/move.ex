defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Door
  alias Game.Session.GMCP

  import Game.Character.Helpers, only: [clear_target: 2]

  @must_be_alive true

  commands [
    "move",
    {"north", ["n"]},
    {"south", ["s"]},
    {"east", ["e"]},
    {"west", ["w"]},
    {"up", ["u"]},
    {"down", ["d"]},
    "open",
    "close",
  ], parse: false

  @impl Game.Command
  def help(:topic), do: "Move"
  def help(:short), do: "Move in a direction"
  def help(:full) do
    """
    Move around rooms.

    Example:
    [ ] > {white}move west{/white}
    [ ] > {white}west{/white}
    [ ] > {white}w{/white}

    Open and close doors.

    Example:
    [ ] > {white}open west{/white}
    [ ] > {white}close west{/white}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments
  """
  @spec parse(command :: String.t) :: {atom}
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

  @doc """
  Move in the direction provided
  """
  @impl Game.Command
  @spec run(args :: [atom()], session :: Session.t, state :: map()) :: :ok
  def run(command, session, state)
  def run({:east}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:east) do
      room_exit = %{east_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:north}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:north) do
      room_exit = %{north_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:south}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:south) do
      room_exit = %{south_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:west}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:west) do
      room_exit = %{west_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:up}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:up) do
      room_exit = %{up_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:down}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room |> Exit.exit_to(:down) do
      room_exit = %{down_id: id} -> session |> maybe_move_to(state, id, room_exit)
      _ -> {:error, :no_exit}
    end
  end
  def run({:open, direction}, _session, state = %{save: %{room_id: room_id}}) do
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
  def run({:close, direction}, _session, state = %{save: %{room_id: room_id}}) do
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
  def maybe_move_to(session, state, room_id, room_exit \\ %{})
  def maybe_move_to(session, state = %{socket: socket}, room_id, room_exit = %{id: exit_id, has_door: true}) do
    case Door.get(exit_id) do
      "open" -> maybe_move_to(session, state, room_id, %{})
      "closed" ->
        Door.set(exit_id, "open")
        socket |> @socket.echo("You opened the door.")
        maybe_move_to(session, state, room_id, room_exit)
    end
  end
  def maybe_move_to(session, state = %{save: %{stats: stats}}, room_id, _) do
    case stats.move_points > 0 do
      true ->
        stats = %{stats | move_points: stats.move_points - 1}
        save = %{state.save | stats: stats}
        session |> move_to(Map.put(state, :save, save), room_id)
      false ->
        state.socket |> @socket.echo("You have no movement points to move in that direction.")
        {:error, :no_movement}
    end
  end

  @doc """
  Move the player to a new room
  """
  def move_to(session, state = %{save: save, user: user}, room_id) do
    @room.leave(save.room_id, {:user, session, user})

    clear_target(state, {:user, user})

    save = %{save | room_id: room_id}
    state = state
    |> Map.put(:save, save)
    |> Map.put(:target, nil)

    @room.enter(room_id, {:user, session, user})

    Game.Command.run(%Game.Command{module: Game.Command.Look, args: {}, system: true}, session, state)
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
end
