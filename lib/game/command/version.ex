defmodule Game.Command.Version do
  @moduledoc """
  The 'version' command
  """

  use Game.Command

  commands(["version"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Version"
  def help(:short), do: "View the running MUD version"

  def help(:full) do
    """
    View the full version of ExVenture running

    Example:
    [ ] > {white}version{/white}
    """
  end

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

  def run({}, %{socket: socket}) do
    socket
    |> @socket.echo(
      "#{ExVenture.version()}\nhttp://exventure.org - https://github.com/oestrich/ex_venture"
    )

    :ok
  end
end
