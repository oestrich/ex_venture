defmodule TestHelpers do
  alias Data.Repo
  alias Data.Config
  alias Data.Item
  alias Data.Room
  alias Data.RoomItem
  alias Data.User
  alias Data.Zone

  def base_save() do
    %Data.Save{
      room_id: 1,
      item_ids: [],
      class: Game.Class.Fighter,
      stats: %{health: 50, strength: 10, dexterity: 10},
      wearing: %{},
      wielding: %{},
    }
  end

  defp user_attributes(attributes) do
    Map.merge(%{
      save: base_save(),
    }, attributes)
  end

  def create_user(attributes) do
    %User{}
    |> User.changeset(user_attributes(attributes))
    |> Repo.insert!
  end

  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name |> to_string, value: value})
    |> Repo.insert!
  end

  def create_room(attributes) do
    %Room{}
    |> Room.changeset(room_attributes(attributes))
    |> Repo.insert!
  end

  defp room_attributes(attributes) do
    Map.merge(%{
      name: "Hallway",
      description: "A long empty hallway",
    }, attributes)
  end

  def create_item(attributes) do
    %Item{}
    |> Item.changeset(item_attributes(attributes))
    |> Repo.insert!
  end

  defp item_attributes(attributes) do
    Map.merge(%{
      name: "Short Sword",
      description: "A slender sword",
      type: "weapon",
      stats: %{},
      effects: [],
    }, attributes)
  end

  def create_room_item(room, item, attributes) do
    %RoomItem{}
    |> RoomItem.changeset(Map.merge(attributes, %{room_id: room.id, item_id: item.id}))
    |> Repo.insert
  end

  def create_zone(attributes) do
    %Zone{}
    |> Zone.changeset(room_attributes(attributes))
    |> Repo.insert!
  end
end
