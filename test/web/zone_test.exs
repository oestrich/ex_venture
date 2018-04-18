defmodule Web.ZoneTest do
  use Data.ModelCase

  alias Web.Zone

  test "creating a new zone adds a child to the zone supervision tree" do
    params = %{name: "The Forest", description: "For level 1-4"}
    {:ok, zone} = Zone.create(params)

    pid = {:via, :swarm, {Game.Zone, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "The Forest"
  end

  test "updating a zone updates the gen server state for that zone" do
    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, zone} = Zone.update(zone.id, %{name: "Forest"})

    pid = {:via, :swarm, {Game.Zone, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "Forest"
  end
end
