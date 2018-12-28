defmodule Game.Command.Abilities do
  @moduledoc """
  The "abilities" command
  """

  use Game.Command

  alias Game.Abilities
  alias Game.Format.Abilities, as: AbilitiesFormat

  commands(["abilities"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Abilities"
  def help(:short), do: "View your ablities"

  def help(:full) do
    """
    View your abilities.

    Example:
    [ ] > {command}abilities{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Abilities.parse("abilities")
      {}

      iex> Abilities.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("abilities"), do: {}

  @doc """
  Echo the currently connected players
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)

  def run({}, state = %{save: save}) do
    abilities =
      save.abilities
      |> Enum.map(fn instance ->
        with {:ok, ability} <- Abilities.get(instance.ability_id) do
          %{instance | ability: ability}
        end
      end)

    state.socket |> @socket.echo(AbilitiesFormat.abilities(abilities))
  end
end
