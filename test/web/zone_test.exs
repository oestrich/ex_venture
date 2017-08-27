defmodule Web.ZoneTest do
  use Data.ModelCase

  alias Web.Zone
  alias Game.Zone.Supervisor, as: ZoneSupervisor

  setup do
    ZoneSupervisor
    |> Supervisor.which_children()
    |> Enum.map(&(Supervisor.delete_child(ZoneSupervisor, elem(&1, 0))))
  end

  test "creating a new zone adds a child to the zone supervision tree" do
    starting_length =  ZoneSupervisor.zones() |> length()

    params = %{name: "The Forest"}
    Zone.create(params)

    final_length = ZoneSupervisor.zones() |> length()
    assert final_length - starting_length == 1
  end
end
