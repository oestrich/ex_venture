defmodule Game.Command.Shops do
  @moduledoc """
  The "shops" command
  """

  use Game.Command

  @commands ["shops"]

  @short_help "View shops and buy from them"
  @full_help """
  Example: shops
  """

  @doc """
  #{@short_help}
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo(Format.shops(room, label: false))
    :ok
  end
end
