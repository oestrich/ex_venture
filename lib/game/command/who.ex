defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

  command "who"

  @short_help "See who is online"
  @full_help """
  #{@short_help}

  Example:
  [ ] > {white}who{/white}
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
      "[#{user.save.level} #{user.class.name} #{user.race.name}] {blue}#{user.name}{/blue}"
    end)
    |> Enum.join("\n")

    socket |> @socket.echo("There are #{players |> length} players online:\n#{names}")
    :ok
  end
end
