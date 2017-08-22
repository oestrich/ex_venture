defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command

  import Game.Character.Target, only: [clear_target: 2]

  @custom_parse true
  @commands ["north", "east", "south", "west"]
  @aliases ["n", "e", "s", "w"]
  @must_be_alive true

  @short_help "Move in a direction"
  @full_help """
  Move around rooms.
  """

  @doc """
  Parse the command into arguments
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(commnd)
  def parse("north"), do: {:north}
  def parse("n"), do: {:north}
  def parse("east"), do: {:east}
  def parse("e"), do: {:east}
  def parse("south"), do: {:south}
  def parse("s"), do: {:south}
  def parse("west"), do: {:west}
  def parse("w"), do: {:west}
  def parse(_), do: {:unknown}

  @doc """
  Move in the direction provided
  """
  @spec run(args :: [atom()], session :: Session.t, state :: map()) :: :ok
  def run(command, session, state)
  def run({:east}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{east_id: nil} -> :ok
        %{east_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run({:north}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn () ->
      room = @room.look(room_id)
      case room do
        %{north_id: nil} -> :ok
        %{north_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run({:south}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{south_id: nil} -> :ok
        %{south_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run({:west}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{west_id: nil} -> :ok
        %{west_id: id} -> session |> move_to(state, id)
      end
    end)
  end

  defp speed_check(state = %{socket: socket}, fun) do
    case Timex.after?(state.last_tick, state.last_move) do
      true ->
        fun.()
      false ->
        socket |> @socket.echo("Slow down.")
        :ok
    end
  end

  defp move_to(session, state = %{save: save, user: user}, room_id) do
    @room.leave(save.room_id, {:user, session, user})

    clear_target(state, {:user, user})

    save = %{save | room_id: room_id}
    state = state
    |> Map.put(:save, save)
    |> Map.put(:last_move, Timex.now())
    |> Map.put(:target, nil)

    @room.enter(room_id, {:user, session, user})

    Game.Command.run({Game.Command.Look, {}}, session, state)
    {:update, state}
  end
end
