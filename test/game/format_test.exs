defmodule Game.FormatTest do
  use ExUnit.Case
  doctest Game.Format

  alias Game.Format

  describe "line wrapping" do
    test "single line" do
      assert Format.wrap("one line") == "one line"
    end

    test "wraps at 80 chars" do
      assert Format.wrap("this line will be split up into two lines because it is longer than 80 characters") ==
        "this line will be split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps at 80 chars - ignores {color} codes when counting" do
      line = "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps at 80 chars - ignores {command} codes when counting" do
      line =
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps and does not chuck newlines" do
      assert Format.wrap("hi\nthere") == "hi\nthere"
      assert Format.wrap("hi\n\n\nthere") == "hi\n\n\nthere"
    end
  end

  describe "shop listing" do
    setup do
      sword = %{name: "Sword", price: 100, quantity: 10}
      shield = %{name: "Shield", price: 80, quantity: -1}
      %{shop: %{name: "Tree Top Stand"}, items: [sword, shield]}
    end

    test "includes shop name", %{shop: shop, items: items} do
      assert Regex.match?(~r/Tree Top Stand/, Format.list_shop(shop, items))
    end

    test "includes shop items", %{shop: shop, items: items} do
      assert Regex.match?(~r/100 gold/, Format.list_shop(shop, items))
      assert Regex.match?(~r/10 left/, Format.list_shop(shop, items))
      assert Regex.match?(~r/Sword/, Format.list_shop(shop, items))
    end

    test "-1 quantity is unlimited", %{shop: shop, items: items} do
      assert Regex.match?(~r/unlimited/, Format.list_shop(shop, items))
    end
  end

  describe "npc status line" do
    setup do
      npc = %{name: "Guard", extra: %{status_line: "[name] is here.", is_quest_giver: false}}

      %{npc: npc}
    end

    test "templates the name in", %{npc: npc} do
      assert Format.npc_name_for_status(npc) == "{npc}Guard{/npc}"
      assert Format.npc_status(npc) == "{npc}Guard{/npc} is here."
    end

    test "if a quest giver it includes a quest mark", %{npc: npc} do
      npc = %{npc | extra: Map.put(npc.extra, :is_quest_giver, true)}
      assert Format.npc_name_for_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest})"
      assert Format.npc_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest}) is here."
    end
  end
end
