defmodule Game.Command.Quit do
  @moduledoc """
  The "quit" command
  """

  use Game.Command

  commands ["quit"]

  @impl Game.Command
  def help(:topic), do: "Quit"
  def help(:short), do: "Leave the game"
  def help(:full) do
    """
    Leave the game and save.

    Example:
    [ ] > {white}quit{/white}
    """
  end

  @doc """
  Save and quit the game
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)
  def run({}, %{socket: socket}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    :ok
  end
end
