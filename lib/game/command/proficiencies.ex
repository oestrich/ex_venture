defmodule Game.Command.Proficiencies do
  @moduledoc """
  The "proficiencies" command
  """

  use Game.Command

  alias Game.Proficiencies
  alias Game.Format.Proficiencies, as: ProficienciesFormat

  commands(["proficiencies"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Proficiencies"
  def help(:short), do: "View your ablities"

  def help(:full) do
    """
    View your proficiencies.

    Example:
    [ ] > {command}proficiencies{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Proficiencies.parse("proficiencies")
      {}

      iex> Proficiencies.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("proficiencies"), do: {}

  @doc """
  Echo the currently connected players
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)

  def run({}, state = %{save: save}) do
    proficiencies =
      save.proficiencies
      |> Enum.map(fn instance ->
        with {:ok, proficiency} <- Proficiencies.get(instance.proficiency_id) do
          %{instance | proficiency: proficiency}
        end
      end)

    state.socket |> @socket.echo(ProficienciesFormat.proficiencies(proficiencies))
  end
end
