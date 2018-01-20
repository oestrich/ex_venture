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
  end

  describe "inventory formatting" do
    setup do
      wearing = %{chest: %{name: "Leather Armor"}}
      wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      items = [
        %{item: %{name: "Potion"}, quantity: 2},
        %{item: %{name: "Dagger"}, quantity: 1},
      ]

      %{currency: 10, wearing: wearing, wielding: wielding, items: items}
    end

    test "displays currency", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You have 10 gold/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wielding", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wielding/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Shield{\/cyan} in your left hand/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Short Sword{\/cyan} in your right hand/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wearing", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wearing/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Leather Armor{\/cyan} on your chest/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays items", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are holding:/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {cyan}Potion x2{\/cyan}/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {cyan}Dagger{\/cyan}/, Format.inventory(currency, wearing, wielding, items))
    end
  end

  describe "room formatting" do
    setup do
      room = %{
        id: 1,
        name: "Hallway",
        description: "A hallway",
        currency: 100,
        players: [%{name: "Player"}],
        npcs: [%{name: "Bandit", status_line: "{name} is here."}],
        exits: [%{south_id: 1}, %{west_id: 1}],
        shops: [%{name: "Hole in the Wall"}],
      }

      items = [%{name: "Sword"}]

      %{room: room, items: items, map: "[ ]"}
    end

    test "includes the room name", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Hallway/, Format.room(room, items, map))
    end

    test "includes the room description", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/A hallway/, Format.room(room, items, map))
    end

    test "includes the mini map", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/[ ]/, Format.room(room, items, map))
    end

    test "includes the room exits", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/north/, Format.room(room, items, map))
      assert Regex.match?(~r/east/, Format.room(room, items, map))
    end

    test "includes currency", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/100 gold/, Format.room(room, items, map))
    end

    test "includes the room items", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Sword/, Format.room(room, items, map))
    end

    test "includes the players", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Player/, Format.room(room, items, map))
    end

    test "includes the npcs", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Bandit/, Format.room(room, items, map))
    end

    test "includes the shops", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Hole in the Wall/, Format.room(room, items, map))
    end
  end

  describe "info formatting" do
    setup do
      stats = %{
        health: 50,
        max_health: 55,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        wisdom: 10,
      }

      save = %Data.Save{level: 1, experience_points: 0, stats: stats}

      user = %{
        name: "hero",
        save: save,
        race: %{name: "Human"},
        class: %{name: "Fighter", points_name: "Skill Points"},
        seconds_online: 61,
      }

      %{user: user}
    end

    test "includes player name", %{user: user} do
      assert Regex.match?(~r/hero/, Format.info(user))
    end

    test "includes player race", %{user: user} do
      assert Regex.match?(~r/Human/, Format.info(user))
    end

    test "includes player class", %{user: user} do
      assert Regex.match?(~r/Fighter/, Format.info(user))
    end

    test "includes player level", %{user: user} do
      assert Regex.match?(~r/Level.+|.+1/, Format.info(user))
    end

    test "includes player xp", %{user: user} do
      assert Regex.match?(~r/XP.+|.+0/, Format.info(user))
    end

    test "includes player health", %{user: user} do
      assert Regex.match?(~r/Health.+|.+50\/55/, Format.info(user))
    end

    test "includes player skill points", %{user: user} do
      assert Regex.match?(~r/Skill Points.+|.+10\/10/, Format.info(user))
    end

    test "includes player move points", %{user: user} do
      assert Regex.match?(~r/Movement.+|.+10\/10/, Format.info(user))
    end

    test "includes player strength", %{user: user} do
      assert Regex.match?(~r/Strength.+|.+10/, Format.info(user))
    end

    test "includes player dexterity", %{user: user} do
      assert Regex.match?(~r/Dexterity.+|.+10/, Format.info(user))
    end

    test "includes player intelligence", %{user: user} do
      assert Regex.match?(~r/Intelligence.+|.+10/, Format.info(user))
    end

    test "includes player wisdom", %{user: user} do
      assert Regex.match?(~r/Wisdom.+|.+10/, Format.info(user))
    end

    test "includes player play time", %{user: user} do
      assert Regex.match?(~r/Play Time.+|.+00h 01m 01s/, Format.info(user))
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

  describe "quest details" do
    setup do
      guard = %{name: "Guard"}
      goblin = %{name: "Goblin"}
      potion = %{id: 5, name: "Potion"}

      step1 = %{id: 1, type: "npc/kill", count: 3, npc: goblin}
      step2 = %{id: 2, type: "item/collect", count: 4, item: potion, item_id: potion.id}

      quest = %{
        id: 1,
        name: "Into the Dungeon",
        description: "Dungeon delving",
        giver: guard,
        quest_steps: [step1, step2],
      }

      progress = %{status: "active", progress: %{step1.id => 2}, quest: quest}
      save = %{items: [%{id: potion.id}, %{id: potion.id}]}

      %{quest: quest, progress: progress, save: save}
    end

    test "includes quest name", %{progress: progress, save: save} do
      assert Regex.match?(~r/Into the Dungeon/, Format.quest_detail(progress, save))
    end

    test "includes quest description", %{progress: progress, save: save} do
      assert Regex.match?(~r/Dungeon delving/, Format.quest_detail(progress, save))
    end

    test "includes quest status", %{progress: progress, save: save} do
      assert Regex.match?(~r/active/, Format.quest_detail(progress, save))
    end

    test "includes npc step", %{progress: progress, save: save} do
      assert Regex.match?(~r(Collect {cyan}Potion{/cyan} - 2/4), Format.quest_detail(progress, save))
    end

    test "includes item step", %{progress: progress, save: save} do
      assert Regex.match?(~r(Kill {yellow}Goblin{/yellow} - 2/3), Format.quest_detail(progress, save))
    end
  end

  describe "npc status line" do
    setup do
      npc = %{name: "Guard", is_quest_giver: false, status_line: "{name} is here."}

      %{npc: npc}
    end

    test "templates the name in", %{npc: npc} do
      assert Format.npc_name_for_status(npc) == "{yellow}Guard{/yellow}"
      assert Format.npc_status(npc) == "{yellow}Guard{/yellow} is here."
    end

    test "if a quest giver it includes a quest mark", %{npc: npc} do
      npc = %{npc | is_quest_giver: true}
      assert Format.npc_name_for_status(npc) == "{yellow}Guard{/yellow} ({yellow}!{/yellow})"
      assert Format.npc_status(npc) == "{yellow}Guard{/yellow} ({yellow}!{/yellow}) is here."
    end
  end
end
