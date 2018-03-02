defmodule Game.Command.Run do
  @moduledoc """
  The "run" command
  """

  use Game.Command

  alias Game.Command
  alias Game.Command.Move
  alias Game.Session.GMCP

  @direction_regex ~r/(?<count>\d+)?(?<direction>[neswudio])/
  @continue_wait Application.get_env(:ex_venture, :game)[:continue_wait]

  commands(["run"])

  @impl Game.Command
  def help(:topic), do: "Run"
  def help(:short), do: "Move around quickly"

  def help(:full) do
    """
    #{help(:short)}. You will stop running if an exit cannot be found.

    Example:
    [ ] > {white}run 3en4s{/white}
    """
  end

  @impl Game.Command
  @doc """
  Run the user around
  """
  def run(command, state)

  def run({directions}, state) when is_list(directions) do
    move(directions, state)
  end

  def run({directions}, state) do
    case parse_run(directions) do
      directions when is_list(directions) ->
        move(directions, state)

      _ ->
        :ok
    end
  end

  # run without directions
  def run({}, %{socket: socket}) do
    socket |> @socket.echo("You run in place.")
    :ok
  end

  @doc """
  Move in the first direction of the list
  """
  def move([direction | directions], state) do
    case Move.run({direction}, state) do
      {:error, :no_exit} ->
        state.socket |> @socket.echo("Could not move #{direction}, no exit found.")
        :ok

      {:error, :no_movement} ->
        :ok

      {:update, state} ->
        maybe_continue(state, directions)
    end
  end

  defp maybe_continue(state, []), do: {:update, state}

  defp maybe_continue(state, directions) do
    state |> GMCP.vitals()

    {:update, state,
     {%Command{module: __MODULE__, args: {directions}, continue: true}, @continue_wait}}
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
        Enum.map(1..count, fn _ -> _direction(direction) end)

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
  def _direction("u"), do: :up
  def _direction("d"), do: :down
  def _direction("i"), do: :in
  def _direction("o"), do: :out
end
