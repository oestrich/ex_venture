alias Data.Repo

alias Data.Class
alias Data.Config
alias Data.Exit
alias Data.HelpTopic
alias Data.Item
alias Data.NPC
alias Data.NPCSpawner
alias Data.Room
alias Data.RoomItem
alias Data.Skill
alias Data.User
alias Data.Zone

defmodule Helpers do
  def add_item_to_room(room, item, attributes) do
    changeset = %RoomItem{} |> RoomItem.changeset(Map.merge(attributes, %{room_id: room.id, item_id: item.id}))
    case changeset |> Repo.insert do
      {:ok, _room_item} ->
        room |> update_room(%{item_ids: [item.id | room.item_ids]})
      _ ->
        raise "Error creating room item"
    end
  end

  def add_npc_to_zone(zone, npc, attributes) do
    %NPCSpawner{}
    |> NPCSpawner.changeset(Map.merge(attributes, %{npc_id: npc.id, zone_id: zone.id}))
    |> Repo.insert!()
  end

  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name, value: value})
    |> Repo.insert
  end

  def create_item(attributes) do
    %Item{}
    |> Item.changeset(attributes)
    |> Repo.insert!
  end

  def create_npc(attributes) do
    %NPC{}
    |> NPC.changeset(attributes)
    |> Repo.insert!
  end

  def create_room(zone, attributes) do
    %Room{}
    |> Room.changeset(Map.merge(attributes, %{zone_id: zone.id}))
    |> Repo.insert!
  end

  def update_room(room, attributes) do
    room
    |> Room.changeset(attributes)
    |> Repo.update!
  end

  def create_exit(attributes) do
    %Exit{}
    |> Exit.changeset(attributes)
    |> Repo.insert!
  end

  def create_user(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert!
  end

  def create_zone(attributes) do
    %Zone{}
    |> Zone.changeset(attributes)
    |> Repo.insert!
  end

  def create_class(attributes) do
    %Class{}
    |> Class.changeset(attributes)
    |> Repo.insert
  end

  def create_skill(class, attributes) do
    %Skill{}
    |> Skill.changeset(Map.merge(attributes, %{class_id: class.id}))
    |> Repo.insert
  end

  def create_help_topic(attributes) do
    %HelpTopic{}
    |> HelpTopic.changeset(attributes)
    |> Repo.insert!
  end
end

defmodule Seeds do
  import Helpers

  def run do
    bandit_hideout = create_zone(%{name: "Bandit Hideout"})
    village = create_zone(%{name: "Village"})

    entrance = create_room(bandit_hideout, %{
      name: "Entrance",
      description: "A large square room with rough hewn walls.",
      x: 4,
      y: 1,
    })

    hallway = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "As you go further west, the hallway descends downward.",
      x: 3,
      y: 1,
    })
    create_exit(%{west_id: hallway.id, east_id: entrance.id})

    hallway_turn = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The hallway bends south, continuing sloping down.",
      x: 2,
      y: 1,
    })
    create_exit(%{west_id: hallway_turn.id, east_id: hallway.id})

    hallway_south = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The south end of the hall has a wooden door embedded in the rock wall.",
      x: 2,
      y: 2,
    })
    create_exit(%{north_id: hallway_turn.id, south_id: hallway_south.id})

    great_room = create_room(bandit_hideout, %{
      name: "Great Room",
      description: "The great room of the bandit hideout. There are several tables along the walls with chairs pulled up. Cards are on the table along with mugs.",
      x: 2,
      y: 3,
    })
    create_exit(%{north_id: hallway_south.id, south_id: great_room.id})

    dorm = create_room(bandit_hideout, %{
      name: "Bedroom",
      description: "There is a bed in the corner with a dirty blanket on top. A chair sits in the corner by a small fire pit.",
      x: 1,
      y: 3,
    })
    create_exit(%{west_id: dorm.id, east_id: great_room.id})

    kitchen = create_room(bandit_hideout, %{
      name: "Kitchen",
      description: "A large cooking fire is at this end of the great room. A pot boils away at over the flame.",
      x: 3,
      y: 3,
    })
    create_exit(%{west_id: great_room.id, east_id: kitchen.id})

    shack = create_room(village, %{
      name: "Shack",
      description: "A small shack built against the rock walls of a small cliff.",
      x: 1,
      y: 1,
    })
    create_exit(%{west_id: entrance.id, east_id: shack.id})

    forest_path = create_room(village, %{
      name: "Forest Path",
      description: "A small path that leads away from the village to the mountain",
      x: 2,
      y: 1,
    })
    create_exit(%{west_id: shack.id, east_id: forest_path.id})

    stats = %{
      health: 25,
      max_health: 25,
      skill_points: 10,
      max_skill_points: 10,
      strength: 13,
      intelligence: 10,
      dexterity: 10,
    }

    bran = create_npc(%{
      name: "Bran",
      hostile: false,
      level: 1,
      experience_points: 124,
      stats: stats,
    })
    add_npc_to_zone(bandit_hideout, bran, %{
      room_id: entrance.id,
      spawn_interval: 15,
    })

    bandit = create_npc(%{
      name: "Bandit",
      hostile: true,
      level: 2,
      experience_points: 230,
      stats: stats,
    })
    add_npc_to_zone(bandit_hideout, bandit, %{
      room_id: great_room.id,
      spawn_interval: 15,
    })
    add_npc_to_zone(bandit_hideout, bandit, %{
      room_id: kitchen.id,
      spawn_interval: 15,
    })

    sword = create_item(%{
      name: "Short Sword",
      description: "A simple blade",
      type: "weapon",
      stats: %{},
      effects: [],
      keywords: ["sword"],
    })
    entrance = entrance |> add_item_to_room(sword, %{spawn_interval: 15})

    leather_armor = create_item(%{
      name: "Leather Armor",
      description: "A simple chestpiece made out of leather",
      type: "armor",
      stats: %{slot: :chest, armor: 5},
      effects: [],
      keywords: ["leather"],
    })
    entrance = entrance |> add_item_to_room(leather_armor, %{spawn_interval: 15})

    elven_armor = create_item(%{
      name: "Elven armor",
      description: "An elven chest piece.",
      type: "armor",
      stats: %{slot: :chest, armor: 10},
      effects: [%{kind: "stats", field: :dexterity, amount: 5}, %{kind: "stats", field: :strength, amount: 5}],
      keywords: ["elven"],
    })
    entrance = entrance |> add_item_to_room(elven_armor, %{spawn_interval: 15})

    save =  %Data.Save{
      room_id: entrance.id,
      channels: ["global", "newbie"],
      level: 1,
      experience_points: 0,
      item_ids: [sword.id],
      wearing: %{},
      wielding: %{},
    }

    {:ok, _} = create_config("game_name", "ExVenture MUD")
    {:ok, _} = create_config("motd", "Welcome to the {white}MUD{/white}")
    {:ok, _} = create_config("starting_save", save |> Poison.encode!)
    {:ok, _} = create_config("regen_tick_count", "7")

    {:ok, fighter} = create_class(%{
      name: "Fighter",
      description: "Uses strength and swords to overcome.",
      points_name: "Skill Points",
      points_abbreviation: "SP",
      regen_health: 2,
      regen_skill_points: 1,
      starting_stats: %{
        health: 25,
        max_health: 25,
        strength: 13,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
      },
    })
    fighter
    |> create_skill(%{
      name: "Slash",
      description: "Use your weapon to slash at your target",
      points: 1,
      user_text: "You slash at {target}.",
      usee_text: "You were slashed at by {user}.",
      command: "slash",
      effects: [
        %{kind: "damage", type: :slashing, amount: 10},
        %{kind: "damage/type", types: [:slashing]},
      ],
    })

    {:ok, mage} = create_class(%{
      name: "Mage",
      description: "Uses intelligence and magic to overcome.",
      points_name: "Mana",
      points_abbreviation: "MP",
      regen_health: 1,
      regen_skill_points: 2,
      starting_stats: %{
        health: 15,
        max_health: 15,
        skill_points: 20,
        max_skill_points: 20,
        strength: 10,
        intelligence: 12,
        dexterity: 12,
      },
    })
    mage
    |> create_skill(%{
      name: "Magic Missile",
      description: "You shoot a bolt of arcane energy out of your hand",
      points: 3,
      user_text: "You shoot a bolt of arcane energy at {target}.",
      usee_text: "{user} shoots a bolt of arcane energy at you.",
      command: "magic missile",
      effects: [
        %{kind: "damage", type: :arcane, amount: 10},
        %{kind: "damage/type", types: [:arcane]},
      ],
    })

    create_help_topic(%{name: "Fighter", keywords: ["fighter"], body: "This class uses physical skills"})
    create_help_topic(%{name: "Mage", keywords: ["mage"], body: "This class uses arcane skills"})

    save = Config.starting_save()
    |> Map.put(:stats, mage.starting_stats())

    create_user(%{name: "eric", password: "password", save: save, flags: ["admin"], class_id: mage.id})
  end
end

Seeds.run
