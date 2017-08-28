defmodule Web.RoomTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    %{zone: zone}
  end

  test "creating a new room adds a child to the room supervision tree", %{zone: zone} do
    params = %{
      name: "Forest Path",
      description: "A small forest path",
    }

    {:ok, room} = Room.create(zone, params)
    assert room.name == "Forest Path"

    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1
  end
end
