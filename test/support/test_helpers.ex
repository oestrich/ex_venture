defmodule TestHelpers do
  alias Data.Repo
  alias Data.Config
  alias Data.Item
  alias Data.Room
  alias Data.User

  def create_user(attributes) do
    %User{}
    |> User.changeset(attributes)
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
    }, attributes)
  end
end
