defmodule Game.Command.Info do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  @commands ["info"]

  @short_help "View stats about your character"
  @full_help """
  Example: info
  """

  @doc """
  Look at your info sheet
  """
  @spec run([], session :: Session.t, state :: map) :: :ok
  def run([], _session, %{socket: socket, user: user}) do
    socket |> @socket.echo(Format.info(user))
    :ok
  end
end
