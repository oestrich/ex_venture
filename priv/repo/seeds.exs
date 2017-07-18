alias Data.Repo

alias Data.Config
alias Data.Room
alias Data.User

defmodule Helpers do
  def create_config(name, value) do
    %Config{}
    |> Config.changeset(%{name: name, value: value})
    |> Repo.insert
  end
end

defmodule Seeds do
  import Helpers

  def run do
    {:ok, hallway} = %Room{}
    |> Room.changeset(%{name: "Hallway", description: "An empty hallway"})
    |> Repo.insert

    {:ok, ante_chamber} = %Room{}
    |> Room.changeset(%{name: "Ante Chamber", description: "The Ante-Chamber", south_id: hallway.id})
    |> Repo.insert

    {:ok, hallway} = hallway
    |> Room.changeset(%{north_id: ante_chamber.id})
    |> Repo.update

    {:ok, _starting_save} = create_config("starting_save", %{room_id: hallway.id} |> Poison.encode!)
    {:ok, _motd} = create_config("motd", "Welcome to the {white}MUD{/white}")

    {:ok, _} = %User{}
    |> User.changeset(%{username: "eric", password: "password", save: Config.starting_save()})
    |> Repo.insert
  end
end

Seeds.run
