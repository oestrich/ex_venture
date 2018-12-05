alias Data.Repo

alias Data.Channel
alias Data.Character
alias Data.Class
alias Data.ClassSkill
alias Data.Config
alias Data.Exit
alias Data.HelpTopic
alias Data.Item
alias Data.NPC
alias Data.NPCItem
alias Data.NPCSpawner
alias Data.Quest
alias Data.QuestStep
alias Data.Race
alias Data.Room
alias Data.RoomItem
alias Data.Script
alias Data.Skill
alias Data.Social
alias Data.User
alias Data.Zone

defmodule Helpers do
  def add_item_to_room(room, item, attributes) do
    changeset = %RoomItem{} |> RoomItem.changeset(Map.merge(attributes, %{room_id: room.id, item_id: item.id}))
    case changeset |> Repo.insert do
      {:ok, _room_item} ->
        room |> update_room(%{items: [Item.instantiate(item) | room.items]})
      _ ->
        raise "Error creating room item"
    end
  end

  def add_item_to_npc(npc, item, params) do
    npc
    |> Ecto.build_assoc(:npc_items)
    |> NPCItem.changeset(Map.put(params, :item_id, item.id))
    |> Repo.insert!()
  end

  def add_npc_to_zone(zone, npc, attributes) do
    %NPCSpawner{}
    |> NPCSpawner.changeset(Map.merge(attributes, %{npc_id: npc.id, zone_id: zone.id}))
    |> Repo.insert!()
  end

  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name, value: value})
    |> Repo.insert!()
  end

  def create_item(attributes) do
    %Item{}
    |> Item.changeset(attributes)
    |> Repo.insert!()
  end

  def create_npc(attributes) do
    %NPC{}
    |> NPC.changeset(attributes)
    |> Repo.insert!()
  end

  def update_npc(npc, attributes) do
    npc
    |> NPC.changeset(attributes)
    |> Repo.update!()
  end

  def create_room(zone, attributes) do
    %Room{}
    |> Room.changeset(Map.merge(attributes, %{zone_id: zone.id}))
    |> Repo.insert!()
  end

  def update_room(room, attributes) do
    room
    |> Room.changeset(attributes)
    |> Repo.update!()
  end

  def create_exit(attributes) do
    reverse_attributes = %{
      start_room_id: attributes.finish_room_id,
      finish_room_id: attributes.start_room_id,
      direction: to_string(Exit.opposite(attributes.direction)),
    }

    %Exit{}
    |> Exit.changeset(reverse_attributes)
    |> Repo.insert!

    %Exit{}
    |> Exit.changeset(attributes)
    |> Repo.insert!()
  end

  def create_user(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert!()
  end

  def create_character(user, attributes) do
    user
    |> Ecto.build_assoc(:characters)
    |> Character.changeset(attributes)
    |> Repo.insert!()
  end

  def create_zone(attributes) do
    %Zone{}
    |> Zone.changeset(attributes)
    |> Repo.insert!()
  end

  def create_race(attributes) do
    %Race{}
    |> Race.changeset(attributes)
    |> Repo.insert!()
  end

  def create_class(attributes) do
    %Class{}
    |> Class.changeset(attributes)
    |> Repo.insert!()
  end

  def create_skill(attributes) do
    %Skill{}
    |> Skill.changeset(attributes)
    |> Repo.insert!()
  end

  def create_class_skill(class, skill) do
    %ClassSkill{}
    |> ClassSkill.changeset(%{class_id: class.id, skill_id: skill.id})
    |> Repo.insert!()
  end

  def create_help_topic(attributes) do
    %HelpTopic{}
    |> HelpTopic.changeset(attributes)
    |> Repo.insert!()
  end

  def create_social(attributes) do
    %Social{}
    |> Social.changeset(attributes)
    |> Repo.insert!()
  end

  def create_channel(name, color \\ "red") do
    %Channel{}
    |> Channel.changeset(%{name: name, color: color})
    |> Repo.insert!()
  end

  def create_quest(params) do
    %Quest{}
    |> Quest.changeset(params)
    |> Repo.insert!()
  end

  def create_quest_step(quest, params) do
    %QuestStep{}
    |> QuestStep.changeset(Map.merge(params, %{quest_id: quest.id}))
    |> Repo.insert!
  end
end

defmodule Seeds do
  import Helpers

  def run do
    bandit_hideout = create_zone(%{name: "Bandit Hideout", description: "A place for bandits to hide out"})
    village = create_zone(%{name: "Village", description: "The local village"})

    entrance = create_room(bandit_hideout, %{
      name: "Entrance",
      description: "A large square room with rough hewn walls.",
      currency: 0,
      x: 4,
      y: 1,
      map_layer: 1,
    })

    hallway = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "As you go further west, the hallway descends downward.",
      currency: 0,
      x: 3,
      y: 1,
      map_layer: 1,
    })
    create_exit(%{direction: "west", start_room_id: entrance.id, finish_room_id: hallway.id})

    hallway_turn = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The hallway bends south, continuing sloping down.",
      currency: 0,
      x: 2,
      y: 1,
      map_layer: 1,
    })
    create_exit(%{direction: "west", start_room_id: hallway.id, finish_room_id: hallway_turn.id})

    hallway_south = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The south end of the hall has a wooden door embedded in the rock wall.",
      currency: 0,
      x: 2,
      y: 2,
      map_layer: 1,
    })
    create_exit(%{direction: "south", start_room_id: hallway_turn.id, finish_room_id: hallway_south.id})

    great_room = create_room(bandit_hideout, %{
      name: "Great Room",
      description: "The great room of the bandit hideout. There are several tables along the walls with chairs pulled up. Cards are on the table along with mugs.",
      currency: 0,
      x: 2,
      y: 3,
      map_layer: 1,
    })
    create_exit(%{direction: "south", start_room_id: hallway_south.id, finish_room_id: great_room.id})

    dorm = create_room(bandit_hideout, %{
      name: "Bedroom",
      description: "There is a bed in the corner with a dirty blanket on top. A chair sits in the corner by a small fire pit.",
      currency: 0,
      x: 1,
      y: 3,
      map_layer: 1,
    })
    create_exit(%{direction: "west", start_room_id: great_room.id, finish_room_id: dorm.id})

    kitchen = create_room(bandit_hideout, %{
      name: "Kitchen",
      description: "A large cooking fire is at this end of the great room. A pot boils away at over the flame.",
      currency: 0,
      x: 3,
      y: 3,
      map_layer: 1,
    })
    create_exit(%{direction: "east", start_room_id: great_room.id, finish_room_id: kitchen.id})

    shack = create_room(village, %{
      name: "Shack",
      description: "A small shack built against the rock walls of a small cliff.",
      currency: 0,
      x: 1,
      y: 1,
      map_layer: 1,
    })
    create_exit(%{direction: "east", start_room_id: entrance.id, finish_room_id: shack.id})

    forest_path = create_room(village, %{
      name: "Forest Path",
      description: "A small path that leads away from the village to the mountain",
      currency: 0,
      x: 2,
      y: 1,
      map_layer: 1,
    })
    create_exit(%{direction: "east", start_room_id: shack.id, finish_room_id: forest_path.id})

    stats = %{
      health_points: 50,
      max_health_points: 50,
      skill_points: 50,
      max_skill_points: 50,
      endurance_points: 50,
      max_endurance_points: 50,
      strength: 10,
      agility: 10,
      intelligence: 10,
      awareness: 10,
      vitality: 10,
      willpower: 10,
    }

    bran = create_npc(%{
      name: "Bran",
      level: 1,
      currency: 0,
      experience_points: 124,
      stats: stats,
      events: [],
      is_quest_giver: true,
    })
    add_npc_to_zone(bandit_hideout, bran, %{
      room_id: entrance.id,
      spawn_interval: 15,
    })

    bandit = create_npc(%{
      name: "Bandit",
      level: 2,
      currency: 100,
      experience_points: 230,
      stats: stats,
      events: [
        %{
          id: UUID.uuid4(),
          type: "room/entered",
          actions: [
            %{type: "commands/target", options: %{player: true}}
          ],
        },
        %{
          id: UUID.uuid4(),
          type: "combat/ticked",
          options: %{
            weight: 10,
          },
          actions: [
            %{type: "commands/skill", options: %{skill: "slash"}}
          ]
        },
      ],
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
      effects: [%{kind: "stats", field: :agility, amount: 5, mode: "add"}, %{kind: "stats", field: :strength, amount: 5, mode: "add"}],
      keywords: ["elven"],
    })
    entrance = entrance |> add_item_to_room(elven_armor, %{spawn_interval: 15})

    potion = create_item(%{
      name: "Potion",
      description: "A healing potion, recover health points",
      type: "basic",
      stats: %{},
      effects: [%{kind: "recover", type: "health", amount: 10}],
      whitelist_effects: ["recover", "stats"],
      is_usable: true,
      amount: 1,
      keywords: [],
    })
    bandit |> add_item_to_npc(potion, %{drop_rate: 80})

    elixir = create_item(%{
      name: "Elixir",
      description: "A healing elixir, recover skill points",
      type: "basic",
      stats: %{},
      effects: [%{kind: "recover", type: "skill", amount: 10}],
      whitelist_effects: ["recover", "stats"],
      is_usable: true,
      amount: 1,
      keywords: [],
    })
    bandit |> add_item_to_npc(elixir, %{drop_rate: 80})

    save = %Data.Save{
      version: 1,
      room_id: entrance.id,
      config: %{},
      stats: %{},
      channels: ["global", "newbie"],
      level: 1,
      level_stats: %{},
      currency: 0,
      experience_points: 0,
      spent_experience_points: 0,
      items: [Item.instantiate(sword)],
      wearing: %{},
      wielding: %{},
    }

    create_config("game_name", "ExVenture MUD")
    create_config("motd", "Welcome to the {white}MUD{/white}")
    create_config("after_sign_in_message", "Thanks for checking out the game!")
    create_config("starting_save", save |> Poison.encode!)
    create_config("regen_tick_count", "7")

    create_race(%{
      name: "Human",
      description: "A human",
      starting_stats: %{
        health_points: 50,
        max_health_points: 50,
        skill_points: 50,
        max_skill_points: 50,
        endurance_points: 50,
        max_endurance_points: 50,
        strength: 10,
        agility: 10,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      },
    })

    dwarf = create_race(%{
      name: "Dwarf",
      description: "A dwarf",
      starting_stats: %{
        health_points: 50,
        max_health_points: 50,
        skill_points: 50,
        max_skill_points: 50,
        endurance_points: 50,
        max_endurance_points: 50,
        strength: 12,
        agility: 8,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      },
    })

    create_race(%{
      name: "Elf",
      description: "An elf",
      starting_stats: %{
        health_points: 50,
        max_health_points: 50,
        skill_points: 50,
        max_skill_points: 50,
        endurance_points: 50,
        max_endurance_points: 50,
        strength: 8,
        agility: 12,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      },
    })

    fighter = create_class(%{
      name: "Fighter",
      description: "Uses strength and swords to overcome.",
    })

    mage = create_class(%{
      name: "Mage",
      description: "Uses intelligence and magic to overcome.",
    })

    slash = create_skill(%{
      level: 1,
      name: "Slash",
      description: "Use your weapon to slash at your target",
      points: 1,
      user_text: "You slash at [target].",
      usee_text: "You were slashed at by [user].",
      command: "slash",
      whitelist_effects: ["damage", "damage/type", "stats"],
      effects: [
        %{kind: "damage", type: "slashing", amount: 10},
        %{kind: "damage/type", types: ["slashing"]},
      ],
    })

    magic_missile = create_skill(%{
      level: 1,
      name: "Magic Missile",
      description: "You shoot a bolt of arcane energy out of your hand",
      points: 2,
      user_text: "You shoot a bolt of arcane energy at [target].",
      usee_text: "[user] shoots a bolt of arcane energy at you.",
      command: "magic missile",
      whitelist_effects: ["damage", "damage/type", "stats"],
      effects: [
        %{kind: "damage", type: "arcane", amount: 10},
        %{kind: "damage/type", types: ["arcane"]},
      ],
    })

    create_skill(%{
      level: 1,
      name: "Heal",
      is_global: true,
      description: "Heal yourself a small amount",
      points: 1,
      user_text: "You heal [target].",
      usee_text: "You were healed by [user].",
      command: "heal",
      whitelist_effects: ["recover", "stats"],
      effects: [
        %{kind: "recover", type: "health", amount: 10},
      ],
    })

    create_class_skill(fighter, slash)
    create_class_skill(mage, magic_missile)

    create_help_topic(%{name: "Fighter", keywords: ["fighter"], body: "This class uses physical skills"})
    create_help_topic(%{name: "Mage", keywords: ["mage"], body: "This class uses arcane skills"})

    create_social(%{
      name: "Smile",
      command: "smile",
      with_target: "[user] smiles at [target].",
      without_target: "[user] smiles.",
    })

    create_channel("global")
    create_channel("newbie", "cyan")

    quest = create_quest(%{
      giver_id: bran.id,
      name: "Finding a Guard",
      description: "You must take out the bandits further down the cave.",
      completed_message: "You did it!",
      script: [
        %Script.Line{
          key: "start",
          message: "Can you take out some bandits?",
          listeners: [
            %{phrase: "yes|bandit", key: "accept"},
          ],
        },
        %Script.Line{
          key: "accept",
          message: "Great!",
          trigger: "quest",
        },
      ],
      level: 1,
      experience: 400,
      currency: 100,
    })

    create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: bandit.id})

    save =
      Game.Config.starting_save()
      |> Map.put(:stats, dwarf.starting_stats())
      |> Map.put(:config, %{
        hints: true,
        prompt: "%h/%Hhp %s/%Ssp %e/%Eep %x",
        pager_size: 20,
        regen_notifications: true,
      })
      |> Map.put(:version, 11)

    user = create_user(%{
      name: "admin",
      password: "password",
      flags: ["admin"],
    })

    create_character(user, %{
      name: "admin",
      race_id: dwarf.id,
      class_id: mage.id,
      save: save,
    })
  end
end

defmodule Seeds.LargeScale do
  import Helpers

  defp generate_rooms(zone) do
    Enum.flat_map(1..12, fn x ->
      Enum.map(1..12, fn y ->
        create_room(zone, %{
          name: "Room #{x}-#{y}",
          description: "A room",
          currency: 0,
          x: x,
          y: y,
          map_layer: 1,
        })
      end)
    end)
  end

  defp generate_exits(rooms) do
    Enum.each(1..12, fn x ->
      Enum.each(1..12, fn y ->
        room = Enum.find(rooms, &(&1.x == x && &1.y == y))
        north_room = Enum.find(rooms, &(&1.x == x && &1.y == y - 1))
        west_room = Enum.find(rooms, &(&1.x == x - 1 && &1.y == y))

        if west_room, do: create_exit(%{direction: "west", finish_room_id: west_room.id, start_room_id: room.id})
        if north_room, do: create_exit(%{direction: "north", finish_room_id: north_room.id, start_room_id: room.id})
      end)
    end)
  end

  def run do
    Enum.each(1..100, fn zone_index ->
      zone = create_zone(%{name: "Zone #{zone_index}", description: "A zone"})

      rooms = generate_rooms(zone)
      generate_exits(rooms)

      stats = %{
        health_points: 25,
        max_health_points: 25,
        skill_points: 10,
        max_skill_points: 10,
        endurance_points: 10,
        max_endurance_points: 10,
        strength: 13,
        agility: 10,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      }

      move_event = %{
        type: "tick",
        id: "d80a37c1-6f7b-4e55-a102-0c1549bab5bd",
        action: %{
          wait: 120,
          type: "move",
          max_distance: 2,
          chance: 120,
        }
      }

      emote_event = %{
        type: "tick",
        id: "5660c186-5fbc-4448-9dc6-20ef5c922d0a",
        action: %{
          wait: 60,
          type: "emote",
          message: "emotes something",
          chance: 60
        }
      }

      Enum.each(1..10, fn npc_index ->
        npc = create_npc(%{
          name: "NPC #{zone.id}-#{npc_index}",
          level: 1,
          currency: 0,
          experience_points: 124,
          stats: stats,
          events: [move_event, emote_event],
          is_quest_giver: false,
        })

        Enum.each(1..20, fn _spawn_index ->
          room = Enum.random(rooms)
          add_npc_to_zone(zone, npc, %{
            room_id: room.id,
            spawn_interval: 15,
          })
        end)
      end)
    end)
  end
end

Seeds.run()
#Seeds.LargeScale.run()
