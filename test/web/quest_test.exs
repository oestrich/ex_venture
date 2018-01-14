defmodule Web.QuestTest do
  use Data.ModelCase

  alias Web.Quest

  test "creating a quest" do
    npc = create_npc()

    params = %{
      "name" => "Finding a Guard",
      "description" => "You must go find and talk to a guard",
      "giver_id" => npc.id,
      "level" => 1,
    }

    {:ok, quest} = Quest.create(params)

    assert quest.name == "Finding a Guard"
  end

  test "updating a quest" do
    npc = create_npc()
    quest = create_quest(npc, %{name: "Finding a Guard"})

    {:ok, quest} = Quest.update(quest.id, %{name: "Kill a Guard"})

    assert quest.name == "Kill a Guard"
  end
end
