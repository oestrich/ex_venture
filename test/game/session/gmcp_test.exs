defmodule Game.Session.GMCPTest do
  use ExUnit.Case

  alias Game.Session.GMCP

  test "character enters - player" do
    assert GMCP.character_enter({:user, %{id: 10, name: "user"}}) ==
      {"Room.Character.Enter", %{type: :player, id: 10, name: "user"}}
  end

  test "character enters - np" do
    assert GMCP.character_enter({:npc, %{id: 10, name: "user"}}) ==
      {"Room.Character.Enter", %{type: :npc, id: 10, name: "user"}}
  end
end
