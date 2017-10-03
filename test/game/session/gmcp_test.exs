defmodule Game.Session.GMCPTest do
  use ExUnit.Case

  alias Game.Session.GMCP

  test "character enters - player" do
    assert GMCP.character_enter({:user, %{id: 10, name: "user"}}) ==
      {"Room.Character.Enter", %{type: :player, id: 10, name: "user"}}
  end

  test "character enters - npc" do
    assert GMCP.character_enter({:npc, %{id: 10, name: "user"}}) ==
      {"Room.Character.Enter", %{type: :npc, id: 10, name: "user"}}
  end

  test "character leaves - player" do
    assert GMCP.character_leave({:user, %{id: 10, name: "user"}}) ==
      {"Room.Character.Leave", %{type: :player, id: 10, name: "user"}}
  end

  test "character leaves - npc" do
    assert GMCP.character_leave({:npc, %{id: 10, name: "user"}}) ==
      {"Room.Character.Leave", %{type: :npc, id: 10, name: "user"}}
  end
end
