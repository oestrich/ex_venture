defmodule Game.Command.Say do
  @moduledoc """
  The "say" command
  """

  use Game.Command

  @commands ["say"]

  @short_help "Talk to other players"
  @full_help """
  Example: say Hello, everyone!

  This is the same room only.
  """

  @doc """
  Says to the current room the player is in
  """
  @spec run(args :: [], command :: String.t, session :: Session.t, state :: map) :: :ok
  def run([message], _command, session, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say({:user, user}, message))
    room_id |> @room.say(session, Message.new(user, message))
    :ok
  end
end
