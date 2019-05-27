defmodule Game.Command.AFK do
  @moduledoc """
  The "afk" command
  """

  use Game.Command

  commands(["afk"], parse: false)

  @impl Game.Command
  def help(:topic), do: "AFK"
  def help(:short), do: "Go away from keyboard"

  def help(:full) do
    """
    This command lets you set your AFK flag for others to see.

    It will toggle your status.

    Example:
    [ ] > {command}afk{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.AFK.parse("afk")
      {:toggle}

      iex> Game.Command.AFK.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("afk"), do: {:toggle}

  @impl Game.Command
  def run(command, state)

  def run({:toggle}, state) do
    state = %{state | is_afk: !state.is_afk}

    case state.is_afk do
      true ->
        state |> Socket.echo("You are now AFK.")

      false ->
        state |> welcome_back()
    end

    {:update, state}
  end

  def welcome_back(state) do
    state |> Socket.echo("Welcome back.")
  end
end
