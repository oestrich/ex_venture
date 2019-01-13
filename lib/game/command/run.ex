defmodule Game.Command.Run do
  @moduledoc """
  The "run" command
  """

  use Game.Command

  alias Game.Command
  alias Game.Command.Move
  alias Game.Session.GMCP

  @direction_regex ~r/(?<count>\d+)?(?<direction>[neswudio]{1,2})/
  @continue_wait Application.get_env(:ex_venture, :game)[:continue_wait]

  commands(["run"])

  @impl Game.Command
  def help(:topic), do: "Run"
  def help(:short), do: "Move around quickly"

  def help(:full) do
    """
    #{help(:short)}. You will stop running if an exit cannot be found.

    You must provide a number before each direction. Possible directions are:

    {white}n{/white}: north
    {white}s{/white}: south
    {white}e{/white}: east
    {white}w{/white}: west
    {white}i{/white}: in
    {white}o{/white}: out
    {white}u{/white}: up
    {white}d{/white}: down
    {white}nw{/white}: north west
    {white}ne{/white}: north east
    {white}sw{/white}: south west
    {white}se{/white}: south east

    Example:
    [ ] > {command}run 3e1n4s{/command}
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
  def run({}, state) do
    state |> Socket.echo(gettext("You run in place."))
  end

  @doc """
  Move in the first direction of the list
  """
  def move([direction | directions], state) do
    case Move.run({:move, direction}, state) do
      {:error, :no_exit} ->
        :ok

      {:error, :no_movement} ->
        :ok

      {:update, state} ->
        maybe_continue(state, directions)
    end
  end

  def move([], _state), do: :ok

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
    |> Enum.reject(&(&1 == :error))
  end

  @doc """
  Expand a single direction command into a list of directions

      iex> Game.Command.Run.expand_direction("3e")
      ["east", "east", "east"]
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

  def _direction("n"), do: "north"
  def _direction("e"), do: "east"
  def _direction("s"), do: "south"
  def _direction("w"), do: "west"
  def _direction("u"), do: "up"
  def _direction("d"), do: "down"
  def _direction("i"), do: "in"
  def _direction("o"), do: "out"
  def _direction("nw"), do: "north west"
  def _direction("ne"), do: "north east"
  def _direction("sw"), do: "south west"
  def _direction("se"), do: "south east"
  def _direction(_), do: :error
end
