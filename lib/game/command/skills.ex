defmodule Game.Command.Skills do
  @moduledoc """
  Parse out class skills
  """

  use Game.Command

  @commands ["skills"]

  @short_help "List out your class skills"
  @full_help """
  Example: skills
  """

  @doc """
  Look at your info sheet
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, user: user}) do
    socket |> @socket.echo(Format.skills(user.class))
    :ok
  end
end
