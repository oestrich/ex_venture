defmodule TestHelpers do
  alias Data.Bug
  alias Data.Class
  alias Data.Config
  alias Data.Exit
  alias Data.HelpTopic
  alias Data.Item
  alias Data.ItemAspect
  alias Data.ItemAspecting
  alias Data.Mail
  alias Data.Note
  alias Data.NPC
  alias Data.NPCItem
  alias Data.NPCSpawner
  alias Data.Quest
  alias Data.QuestProgress
  alias Data.QuestStep
  alias Data.Race
  alias Data.Repo
  alias Data.Room
  alias Data.RoomItem
  alias Data.Shop
  alias Data.ShopItem
  alias Data.Skill
  alias Data.User
  alias Data.Zone

  def base_stats() do
    %{
      health: 50,
      max_health: 50,
      skill_points: 50,
      max_skill_points: 50,
      move_points: 10,
      max_move_points: 10,
      strength: 10,
      dexterity: 10,
      intelligence: 10,
      wisdom: 10,
    }
  end

  def base_save() do
    %Data.Save{
      room_id: 1,
      channels: [],
      level: 1,
      experience_points: 0,
      currency: 0,
      items: [],
      stats: base_stats(),
      wearing: %{},
      wielding: %{},
      version: 2,
    }
  end

  def user_attributes(attributes) do
    Map.merge(%{
      save: base_save(),
      race_id: create_race().id,
      class_id: create_class().id,
    }, attributes)
  end

  def create_user(attributes \\ %{name: "player", password: "password"}) do
    %User{}
    |> User.changeset(user_attributes(attributes))
    |> Repo.insert!
  end

  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name |> to_string, value: value})
    |> Repo.insert!
  end

  def create_room(zone, attributes \\ %{}) do
    %Room{}
    |> Room.changeset(Map.merge(room_attributes(attributes), %{zone_id: zone.id}))
    |> Repo.insert!
  end

  def room_attributes(attributes) do
    Map.merge(%{
      name: "Hallway",
      description: "A long empty hallway",
      currency: 0,
      x: 1,
      y: 1,
      map_layer: 1,
    }, attributes)
  end

  def create_exit(attributes) do
    %Exit{}
    |> Exit.changeset(attributes)
    |> Repo.insert!
  end

  def create_item_aspect(attributes \\ %{}) do
    %ItemAspect{}
    |> ItemAspect.changeset(item_aspect_attributes(attributes))
    |> Repo.insert!
  end

  def item_aspect_attributes(attributes) do
    Map.merge(%{
      name: "Swords",
      description: "Tag for swords",
      type: "weapon",
      stats: %{},
      effects: [],
    }, attributes)
  end

  def item_instance(id) when is_integer(id) do
    Item.instantiate(%Item{id: id})
  end
  def item_instance(item = %Item{}) do
    Item.instantiate(item)
  end

  def create_item(attributes \\ %{}) do
    %Item{}
    |> Item.changeset(item_attributes(attributes))
    |> Repo.insert!
  end

  def item_attributes(attributes) do
    Map.merge(%{
      name: "Short Sword",
      description: "A slender sword",
      tags: [],
      type: "weapon",
      stats: %{},
      effects: [],
      is_usable: false,
      amount: 1,
    }, attributes)
  end

  def create_item_aspecting(item, item_aspect) do
    item
    |> Ecto.build_assoc(:item_aspectings)
    |> ItemAspecting.changeset(%{"item_aspect_id" => item_aspect.id})
    |> Repo.insert!()
  end

  def create_room_item(room, item, attributes) do
    %RoomItem{}
    |> RoomItem.changeset(Map.merge(attributes, %{room_id: room.id, item_id: item.id}))
    |> Repo.insert!
  end

  def create_zone(attributes \\ %{}) do
    %Zone{}
    |> Zone.changeset(zone_attributes(attributes))
    |> Repo.insert!
  end

  def zone_attributes(attributes) do
    Map.merge(%{
      name: "Hidden Forest",
      description: "For level 1s",
    }, attributes)
  end

  def race_attributes(attributes) do
    Map.merge(%{
      name: "Human",
      description: "A human",
      starting_stats: %{
        health: 25,
        max_health: 25,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        wisdom: 10,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
      },
    }, attributes)
  end

  def create_race(attributes \\ %{}) do
    %Race{}
    |> Race.changeset(race_attributes(attributes))
    |> Repo.insert!
  end

  def class_attributes(attributes) do
    Map.merge(%{
      name: "Fighter",
      description: "A fighter",
      points_name: "Skill Points",
      points_abbreviation: "SP",
      regen_health: 1,
      regen_skill_points: 1,
      each_level_stats: %{
        health: 5,
        max_health: 5,
        strength: 1,
        dexterity: 1,
        intelligence: 1,
        wisdom: 1,
        skill_points: 5,
        max_skill_points: 5,
        move_points: 2,
        max_move_points: 10,
      },
    }, attributes)
  end

  def create_class(attributes \\ %{}) do
    %Class{}
    |> Class.changeset(class_attributes(attributes))
    |> Repo.insert!
  end

  def skill_attributes(class, attributes) do
    Map.merge(%{
      class_id: class.id,
      name: "Slash",
      command: "slash",
      description: "Slash at the target",
      level: 1,
      user_text: "You slash at your {target}",
      usee_text: "You are slashed at by {who}",
      points: 3,
      effects: [],
    }, attributes)
  end

  def create_skill(class, attributes \\ %{}) do
    %Skill{}
    |> Skill.changeset(skill_attributes(class, attributes))
    |> Repo.insert!
  end

  def npc_attributes(attributes) do
    Map.merge(%{
      name: "Bandit",
      level: 1,
      experience_points: 124,
      currency: 0,
      events: [],
      status_line: "{name} is here.",
      description: "{status_line}",
      stats: %{
        health: 25,
        max_health: 25,
        skill_points: 10,
        max_skill_points: 10,
        strength: 13,
        dexterity: 10,
        intelligence: 10,
        wisdom: 10,
        move_points: 1,
        max_move_points: 10,
      },
    }, attributes)
  end

  def create_npc(attributes \\ %{}) do
    %NPC{}
    |> NPC.changeset(npc_attributes(attributes))
    |> Repo.insert!
  end

  def create_npc_spawner(npc, attributes) do
    npc
    |> Ecto.build_assoc(:npc_spawners)
    |> NPCSpawner.changeset(attributes)
    |> Repo.insert!
  end

  def create_npc_item(npc, item, attributes \\ %{}) do
    npc
    |> Ecto.build_assoc(:npc_items)
    |> NPCItem.changeset(Map.merge(attributes, %{item_id: item.id}))
    |> Repo.insert!
  end

  def create_help_topic(attributes) do
    %HelpTopic{}
    |> HelpTopic.changeset(attributes)
    |> Repo.insert!
  end

  def shop_attributes(attributes) do
    Map.merge(%{
      name: "Tree Stand Shop",
    }, attributes)
  end

  def create_shop(room, attributes \\ %{}) do
    room
    |> Ecto.build_assoc(:shops)
    |> Shop.changeset(shop_attributes(attributes))
    |> Repo.insert!
  end

  def create_shop_item(shop, item, attributes \\ %{}) do
    shop
    |> Ecto.build_assoc(:shop_items)
    |> ShopItem.changeset(Map.merge(attributes, %{item_id: item.id}))
    |> Repo.insert!
  end

  def create_mail(sender, receiver, params) do
    %Mail{}
    |> Mail.changeset(Map.merge(params, %{sender_id: sender.id, receiver_id: receiver.id}))
    |> Repo.insert!
  end

  def create_bug(reporter, params) do
    %Bug{}
    |> Bug.changeset(Map.merge(params, %{reporter_id: reporter.id}))
    |> Repo.insert!
  end

  def create_note(params) do
    %Note{}
    |> Note.changeset(note_attributes(params))
    |> Repo.insert!
  end

  def note_attributes(params) do
    Map.merge(%{
      name: "Gods",
      body: "There are gods in this world.",
      tags: ["gods", "magic"],
    }, params)
  end

  def create_quest(giver, params) do
    %Quest{}
    |> Quest.changeset(quest_attributes(giver, params))
    |> Repo.insert!
  end

  def quest_attributes(giver, params) do
    Map.merge(%{
      name: "Finding a Guard",
      description: "You must find and talk to a guard",
      completed_message: "You did it!",
      level: 1,
      experience: 100,
      giver_id: giver.id,
    }, params)
  end

  def create_quest_step(quest, params) do
    %QuestStep{}
    |> QuestStep.changeset(quest_step_attributes(quest, params))
    |> Repo.insert!
  end

  def quest_step_attributes(quest, params) do
    Map.merge(%{
      quest_id: quest.id,
    }, params)
  end

  def create_quest_progress(user, quest, params \\ %{}) do
    %QuestProgress{}
    |> QuestProgress.changeset(quest_progress_attributes(user, quest, params))
    |> Repo.insert!
  end

  def quest_progress_attributes(user, quest, params) do
    Map.merge(%{
      user_id: user.id,
      quest_id: quest.id,
      status: "active",
      progress: %{},
    }, params)
  end
end
