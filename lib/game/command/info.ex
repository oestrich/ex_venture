defmodule Game.Command.Info do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  @doc """
  Look at your info sheet
  """
  @spec run([], session :: Session.t, state :: map) :: :ok
  def run([], _session, %{socket: socket, user: user}) do
    socket |> @socket.echo(Format.info(user))
    :ok
  end
end
