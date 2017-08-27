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
end
