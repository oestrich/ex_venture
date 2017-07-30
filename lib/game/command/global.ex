defmodule Game.Command.Global do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  @commands ["global"]

  @short_help "Talk to other players"
  @full_help """
  Example: say Hello, everyone!

  This chats to every player connected
  """

  @doc """
  Send to all connected players
  """
  def run(command, session, state)
  def run({message}, session, %{socket: socket, user: user}) do
    message = ~s({red}[global]{/red} {blue}#{user.name}{/blue} says, {green}"#{message}"{/green})

    socket |> @socket.echo(message)

    Session.Registry.connected_players()
    |> Enum.reject(&(elem(&1, 0) == session)) # don't send to your own
    |> Enum.map(fn ({session, _user}) ->
      Session.echo(session, message)
    end)

    :ok
  end
end
