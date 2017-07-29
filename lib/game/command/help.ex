defmodule Game.Command.Help do
  @moduledoc """
  The "help" command
  """

  use Game.Command

  @commands ["help"]

  alias Game.Help

  @doc """
  View help
  """
  @spec run(args :: [], command :: String.t, session :: Session.t, state :: map) :: :ok
  def run([], _command, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
    :ok
  end
  def run([topic], _command, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
    :ok
  end
end
