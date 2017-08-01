defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

  @commands ["who"]

  @short_help "See who is online"
  @full_help """
  Example: who
  """

  @doc """
  Echo the currently connected players
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket}) do
    players = Session.Registry.connected_players()

    names = players
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.name}{/blue}"
    end)
    |> Enum.join("\n")

    socket |> @socket.echo("There are #{players |> length} players online:\n#{names}")
    :ok
  end
end
