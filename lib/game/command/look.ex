defmodule Game.Command.Look do
  @moduledoc """
  The "look" command
  """

  use Game.Command

  @doc """
  Look around the current room
  """
  @spec run([], session :: Session.t, state :: map) :: :ok
  def run([], _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo(Format.room(room))
    :ok
  end
end
