defmodule Web.ZoneTest do
  use Data.ModelCase

  alias Game.World
  alias Web.Zone

  test "creating a new zone adds a child to the zone supervision tree" do
    starting_length =  World.zones() |> length()

    params = %{name: "The Forest"}
    Zone.create(params)

    final_length = World.zones() |> length()
    assert final_length - starting_length == 1
  end

  test "updating a zone updates the gen server state for that zone" do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    {:ok, zone} = Zone.update(zone.id, %{name: "Forest"})

    pid = {:via, Registry, {Game.Zone.Registry, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "Forest"
  end
end
