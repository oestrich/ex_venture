defmodule Game.Command.Quit do
  @moduledoc """
  The "quit" command
  """

  use Game.Command

  commands ["quit"]

  @short_help "Leave the game"
  @full_help """
  Leave the game and save.

  Example:
  [ ] > {white}quit{/white}
  """

  @doc """
  Save and quit the game
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    :ok
  end
end
