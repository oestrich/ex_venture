defmodule Game.Command.Move do
  @moduledoc """
  The movement commands: north, east, south, west
  """

  use Game.Command

  @commands ["north", "east", "south", "west"]
  @aliases ["n", "e", "s", "w"]

  @short_help "Move in a direction"
  @full_help """
  Move around rooms.
  """

  @doc """
  Move in the direction provided
  """
  @spec run([direction :: atom()], session :: Session.t, state :: map()) :: :ok
  def run([:east], session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{east_id: nil} -> :ok
        %{east_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run([:north], session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn () ->
      room = @room.look(room_id)
      case room do
        %{north_id: nil} -> :ok
        %{north_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run([:south], session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{south_id: nil} -> :ok
        %{south_id: id} -> session |> move_to(state, id)
      end
    end)
  end
  def run([:west], session, state = %{save: %{room_id: room_id}}) do
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

    save = %{save | room_id: room_id}
    state = %{state | save: save, last_move: Timex.now()}

    @room.enter(room_id, {:user, session, user})

    Game.Command.run({Game.Command.Look, []}, session, state)
    {:update, state}
  end
end
