defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  @doc """
  Says to the current room the player is in
  """
  @spec run([message :: String.t], session :: Session.t, state :: map) :: :ok
  def run([message], session, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say(user, message))
    room_id |> @room.say(session, Message.new(user, message))
    :ok
  end
end
