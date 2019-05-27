defmodule Game.Command.Quit do
  @moduledoc """
  The "quit" command
  """

  use Game.Command

  commands(["quit"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Quit"
  def help(:short), do: "Leave the game"

  def help(:full) do
    """
    Leave the game and save.

    Example:
    [ ] > {command}quit{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Quit.parse("quit")
      {}

      iex> Game.Command.Quit.parse("quit extra")
      {:error, :bad_parse, "quit extra"}

      iex> Game.Command.Quit.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("quit"), do: {}

  @impl Game.Command
  @doc """
  Save and quit the game
  """
  def run(command, state)

  def run({}, state) do
    state |> Socket.echo("Good bye.")
    state |> Socket.disconnect()

    :ok
  end
end
