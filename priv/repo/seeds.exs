alias Data.Repo

alias Data.Class
alias Data.Config
alias Data.Item
alias Data.NPC
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

  def create_npc(room, attributes) do
    %NPC{}
    |> NPC.changeset(Map.merge(attributes, %{room_id: room.id}))
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
end

defmodule Seeds do
  import Helpers

  def run do
    bandit_hideout = create_zone(%{name: "Bandit Hideout"})
    village = create_zone(%{name: "Village"})

    entrance = create_room(bandit_hideout, %{
      name: "Entrance",
      description: "A large square room with rough hewn walls.",
    })

    hallway = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "As you go further west, the hallway descends downward.",
      east_id: entrance.id,
    })
    entrance = update_room(entrance, %{west_id: hallway.id})

    hallway_turn = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The hallway bends south, continuing sloping down.",
      east_id: hallway.id,
    })
    hallway = update_room(hallway, %{west_id: hallway_turn.id})

    hallway_south = create_room(bandit_hideout, %{
      name: "Hallway",
      description: "The south end of the hall has a wooden door embedded in the rock wall.",
      north_id: hallway_turn.id,
    })
    hallway_turn = update_room(hallway_turn, %{south_id: hallway_south.id})

    great_room = create_room(bandit_hideout, %{
      name: "Great Room",
      description: "The great room of the bandit hideout. There are several tables along the walls with chairs pulled up. Cards are on the table along with mugs.",
      north_id: hallway_south.id,
    })
    hallway_south = update_room(hallway_south, %{south_id: great_room.id})

    dorm = create_room(bandit_hideout, %{
      name: "Bedroom",
      description: "There is a bed in the corner with a dirty blanket on top. A chair sits in the corner by a small fire pit.",
      east_id: great_room.id,
    })
    great_room = update_room(great_room, %{west_id: dorm.id})

    kitchen = create_room(bandit_hideout, %{
      name: "Kitchen",
      description: "A large cooking fire is at this end of the great room. A pot boils away at over the flame.",
      west_id: great_room.id,
    })
    great_room = update_room(great_room, %{east_id: kitchen.id})

    shack = create_room(village, %{
      name: "Shack",
      description: "A small shack built against the rock walls of a small cliff.",
      west_id: entrance.id,
    })
    entrance = update_room(entrance, %{east_id: shack.id})

    forest_path = create_room(village, %{
      name: "Forest Path",
      description: "A small path that leads away from the village to the mountain",
      west_id: shack.id,
    })
    shack = update_room(shack, %{east_id: forest_path.id})

    entrance |> create_npc(%{name: "Bran", hostile: false})
    great_room |> create_npc(%{name: "Bandit", hostile: true})

    sword = create_item(%{
      name: "Short Sword",
      description: "A simple blade",
      type: "weapon",
      stats: %{},
      effects: [],
      keywords: ["sword"],
    })
    entrance = entrance |> add_item_to_room(sword, %{interval: 15})

    leather_armor = create_item(%{
      name: "Leather Armor",
      description: "A simple chestpiece made out of leather",
      type: "armor",
      stats: %{slot: :chest, armor: 5},
      effects: [],
      keywords: ["leather"],
    })
    entrance = entrance |> add_item_to_room(leather_armor, %{interval: 15})

    save =  %{
      room_id: entrance.id,
      item_ids: [sword.id],
      wearing: %{},
      wielding: %{},
    }
    {:ok, _starting_save} = create_config("starting_save", save |> Poison.encode!)
    {:ok, _motd} = create_config("motd", "Welcome to the {white}MUD{/white}")

    {:ok, fighter} = create_class(%{
      name: "Fighter",
      description: "Uses strength and swords to overcome.",
      starting_stats: %{
        health: 25,
        strength: 13,
        dexterity: 10,
      },
    })
    fighter
    |> create_skill(%{
      name: "Slash",
      description: "You slash at {target}.",
      command: "slash",
      effects: [%{kind: "damage", type: :slashing, amount: 10}],
    })

    _mage = create_class(%{
      name: "Mage",
      description: "Uses intelligence and magic to overcome.",
      starting_stats: %{
        health: 25,
        strength: 10,
        dexterity: 12,
      },
    })

    save = Config.starting_save()
    |> Map.put(:stats, fighter.starting_stats())

    create_user(%{name: "eric", password: "password", save: save, flags: ["admin"], class_id: fighter.id})
  end
end

Seeds.run
