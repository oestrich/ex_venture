defmodule Game.Command.Map do
  @moduledoc """
  The "map" command
  """

  use Game.Command
  use Game.Room
  use Game.Zone

  alias Game.Session.GMCP

  commands ["map"]

  def help(:topic), do: "Map"
  def help(:short), do: "View a map of the zone"
  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {white}map{/white}
    """
  end

  @doc """
  View a map of the zone
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer})
    mini_map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)
    state |> GMCP.map(mini_map)
    socket |> @socket.echo(map)
    :ok
  end
end
