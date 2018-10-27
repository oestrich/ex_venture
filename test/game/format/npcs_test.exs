defmodule Game.Format.NPCsTest do
  use ExUnit.Case

  alias Game.Format.NPCs

  doctest Game.Format.NPCs

  describe "npc status line" do
    setup do
      npc = %{name: "Guard", extra: %{status_line: "[name] is here.", is_quest_giver: false}}

      %{npc: npc}
    end

    test "templates the name in", %{npc: npc} do
      assert NPCs.npc_name_for_status(npc) == "{npc}Guard{/npc}"
      assert NPCs.npc_status(npc) == "{npc}Guard{/npc} is here."
    end

    test "if a quest giver it includes a quest mark", %{npc: npc} do
      npc = %{npc | extra: Map.put(npc.extra, :is_quest_giver, true)}
      assert NPCs.npc_name_for_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest})"
      assert NPCs.npc_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest}) is here."
    end
  end
end
