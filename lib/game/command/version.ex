defmodule Game.Command.Version do
  @moduledoc """
  The 'version' command
  """

  use Game.Command

  commands(["version"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Version"
  def help(:short), do: "View the running version of ExVenture"

  def help(:full) do
    """
    View the full version of ExVenture running.

    Example:
    [ ] > {command}version{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Version.parse("version")
      {}

      iex> Game.Command.Version.parse("version extra")
      {:error, :bad_parse, "version extra"}

      iex> Game.Command.Version.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("version"), do: {}

  @impl Game.Command
  @doc """
  View version information
  """
  def run(command, state)

  def run({}, state) do
    version = """
    #{ExVenture.version()}
    https://exventure.org - https://github.com/oestrich/ex_venture
    """

    state |> Socket.echo(version)
  end
end
