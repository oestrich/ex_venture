defmodule Game.Command.Quit do
  @moduledoc """
  The "quit" command
  """

  use Game.Command

  @commands ["quit"]

  @short_help "Leave the game"
  @full_help """
  Example: quit
  """

  @doc """
  Save and quit the game
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, session, %{socket: socket, user: user, save: save}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    @room.leave(save.room_id, {:user, session, user})

    :ok
  end
end
