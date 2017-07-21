defmodule Game.Command.Global do
  @moduledoc """
  The "global" command
  """

  use Game.Command

  @doc """
  Send to all connected players
  """
  @spec run([message :: String.t], session :: Session.t, state :: Map.t) :: :ok
  def run([message], session, %{socket: socket, user: user}) do
    message = ~s({red}[global]{/red} {blue}#{user.username}{/blue} says, {green}"#{message}"{/green})

    socket |> @socket.echo(message)

    Session.Registry.connected_players()
    |> Enum.reject(&(elem(&1, 0) == session)) # don't send to your own
    |> Enum.map(fn ({session, _user}) ->
      Session.echo(session, message)
    end)

    :ok
  end
end
