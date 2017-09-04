defmodule Web.NPCTest do
  use Data.ModelCase

  alias Web.NPC

  test "create a new npc" do
    params = %{
      "name" => "Bandit",
      "hostile" => "false",
      "level" => "1",
      "experience_points" => "124",
      "stats" => %{
        health: 25,
        max_health: 25,
        strength: 10,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
      } |> Poison.encode!(),
    }

    {:ok, npc} = NPC.create(params)

    assert npc.name == "Bandit"
  end

  test "updating a npc" do
    npc = create_npc(%{name: "Fighter"})

    {:ok, npc} = NPC.update(npc.id, %{name: "Barbarian"})

    assert npc.name == "Barbarian"
  end
end
