defmodule Game.Command.Version do
  @moduledoc """
  The 'version' command
  """

  use Game.Command

  commands ["version"]

  @short_help "View the running MUD version"
  @full_help """
  View the full version of ExVenture running

  Example:
  [ ] > {white}version{/white}
  """

  @doc """
  #{@short_help}
  """
  @spec run(args :: {atom, String.t}, session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket}) do
    socket |> @socket.echo("#{ExVenture.version()}\nhttp://exventure.org - https://github.com/oestrich/ex_venture")
    :ok
  end
end
