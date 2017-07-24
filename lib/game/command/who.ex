defmodule Game.Command.Who do
  @moduledoc """
  The "who" command
  """

  use Game.Command

  @doc """
  Echo the currently connected players
  """
  @spec run([], session :: Session.t, state :: map) :: :ok
  def run([], _session, %{socket: socket}) do
    names = Session.Registry.connected_players()
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.name}{/blue}\n"
    end)
    |> Enum.join("")

    socket |> @socket.echo("Players online:\n#{names}")
    :ok
  end
end
