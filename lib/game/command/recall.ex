defmodule Game.Command.Recall do
  @moduledoc """
  The "recall" command
  """

  use Game.Command
  use Game.Zone

  commands(["recall"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Recall"
  def help(:short), do: "Recall to the zone's graveyard"

  def help(:full) do
    """
    #{help(:short)}. Spends all endurance points, and you must have >90% left.

    [ ] > {command}recall{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Recall.parse("recall")
      {}

      iex> Game.Command.Recall.parse("recall extra")
      {:error, :bad_parse, "recall extra"}

      iex> Game.Command.Recall.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("recall"), do: {}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({}, state) do
    state
    |> check_endurance_points()
    |> maybe_recall()
  end

  def check_endurance_points(state = %{save: %{stats: stats}}) do
    case stats.endurance_points / stats.max_endurance_points do
      ratio when ratio > 0.9 ->
        state

      _ ->
        min = round(stats.max_endurance_points * 0.9)

        state.socket
        |> @socket.echo(
          "You do not have enough endurance points to recall. You must have at least #{min}mp first."
        )
    end
  end

  defp maybe_recall(:ok), do: :ok

  defp maybe_recall(state = %{save: save}) do
    {:ok, room} = save.room_id |> @environment.look()

    case @zone.graveyard(room.zone_id) do
      {:ok, graveyard_id} ->
        save = %{save | stats: %{save.stats | endurance_points: 0}}

        user = %{state.user | save: save}
        state = %{state | user: user, save: save}

        Session.teleport(self(), graveyard_id)

        state.socket |> @socket.echo("Recalling to the zone's graveyard...")

        {:update, state}

      {:error, :no_graveyard} ->
        state.socket |> @socket.echo("You cannot recall here.")
    end
  end
end
