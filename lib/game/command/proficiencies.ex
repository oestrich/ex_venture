defmodule Game.Command.Proficiencies do
  @moduledoc """
  The "proficiencies" command
  """

  use Game.Command

  alias Game.Proficiencies
  alias Game.Format.Proficiencies, as: FormatProficiencies

  commands(["proficiencies"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Proficiencies"
  def help(:short), do: "View your proficiencies"

  def help(:full) do
    """
    View your proficiencies:
    [ ] > {command}proficiencies{/command}

    View all available proficiencies:
    [ ] > {command}proficiencies all{/command}
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
  def parse("proficiencies all"), do: {:all}

  @doc """
  Echo the currently connected players
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)

  def run({}, state = %{save: save}) do
    proficiencies = Proficiencies.proficiencies(save.proficiencies)
    state |> Socket.echo(FormatProficiencies.proficiencies(proficiencies))
  end

  def run({:all}, state) do
    proficiencies = Enum.sort_by(Proficiencies.all(), &(&1.name))
    state |> Socket.echo(FormatProficiencies.list(proficiencies))
  end
end
