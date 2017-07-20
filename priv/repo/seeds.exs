alias Data.Repo

alias Data.Config
alias Data.NPC
alias Data.Room
alias Data.User

defmodule Helpers do
  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name, value: value})
    |> Repo.insert
  end

  def create_npc(room, attributes) do
    %NPC{}
    |> NPC.changeset(Map.merge(attributes, %{room_id: room.id}))
    |> Repo.insert
  end

  def create_room(attributes) do
    %Room{}
    |> Room.changeset(attributes)
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
end

defmodule Seeds do
  import Helpers

  def run do
    hallway = create_room(%{name: "Hallway", description: "An empty hallway"})
    ante_chamber = create_room(%{name: "Ante Chamber", description: "The Ante-Chamber", south_id: hallway.id})

    hallway = update_room(hallway, %{north_id: ante_chamber.id})

    hallway |> create_npc(%{name: "Morfen"})

    {:ok, _starting_save} = create_config("starting_save", %{room_id: hallway.id} |> Poison.encode!)
    {:ok, _motd} = create_config("motd", "Welcome to the {white}MUD{/white}")

    create_user(%{username: "eric", password: "password", save: Config.starting_save()})
  end
end

Seeds.run
