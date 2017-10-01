defmodule Game.Command.Run do
  @moduledoc """
  The "run" command
  """

  use Game.Command

  alias Game.Command.Move
  alias Game.Session.GMCP

  @direction_regex ~r/(?<count>\d+)?(?<direction>[nesw])/
  @continue_wait Application.get_env(:ex_venture, :game)[:continue_wait]

  @commands ["run"]

  @short_help "Move around quickly"
  @full_help """
  #{@short_help}. You will stop running if an exit cannot be found.

  Example:
  [ ] > {white}run 3en4s{/white}
  """

  @doc """
  Run the user around
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({directions}, session, state) when is_list(directions) do
    move(directions, session, state)
  end
  def run({directions}, session, state) do
    case parse_run(directions) do
      directions when is_list(directions) ->
        move(directions, session, state)
      _ -> :ok
    end
  end

  @doc """
  Move in the first direction of the list
  """
  def move([direction | directions], session, state) do
    case Move.run({direction}, session, state) do
      {:error, :no_exit} ->
        state.socket |> @socket.echo("Could not move #{direction}, no exit found.")
        :ok
      {:error, :no_movement} ->
        :ok
      {:update, state} -> maybe_continue(state, directions)
    end
  end

  defp maybe_continue(state, []), do: {:update, state}
  defp maybe_continue(state, directions) do
    state |> GMCP.vitals()
    {:update, state, {__MODULE__, {directions}, @continue_wait}}
  end

  @doc """
  Parse a run's direction into commands
  """
  def parse_run(directions) do
    directions
    |> String.split(@direction_regex, include_captures: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.flat_map(&expand_direction/1)
  end

  @doc """
  Expand a single direction command into a list of directions

      iex> Game.Command.Run.expand_direction("3e")
      [:east, :east, :east]
  """
  def expand_direction(direction) do
    case Regex.named_captures(@direction_regex, direction) do
      %{"count" => count, "direction" => direction} when count != "" ->
        count = String.to_integer(count)
        Enum.map(1..count, fn (_) -> _direction(direction) end)
      %{"direction" => direction} ->
        [_direction(direction)]
      _ ->
        []
    end
  end

  def _direction("n"), do: :north
  def _direction("e"), do: :east
  def _direction("s"), do: :south
  def _direction("w"), do: :west
end
