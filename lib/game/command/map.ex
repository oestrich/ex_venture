defmodule Game.Command.Map do
  @moduledoc """
  The "map" command
  """

  use Game.Command
  use Game.Room
  use Game.Zone

  @commands ["map"]

  @short_help "View a map of the zone"
  @full_help """
  #{@short_help}

  Example:
  [ ] > {white}map{/white}
  """

  @doc """
  #{@short_help}
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    map = room.zone_id |> @zone.map({room.x, room.y})
    socket |> @socket.echo(map)
    :ok
  end
end
