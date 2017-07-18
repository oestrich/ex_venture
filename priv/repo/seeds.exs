alias Data.Repo

alias Data.Config
alias Data.Room
alias Data.User

{:ok, hallway} = %Room{}
|> Room.changeset(%{name: "Hallway", description: "An empty hallway"})
|> Repo.insert

{:ok, ante_chamber} = %Room{}
|> Room.changeset(%{name: "Ante Chamber", description: "The Ante-Chamber", south_id: hallway.id})
|> Repo.insert

{:ok, hallway} = hallway
|> Room.changeset(%{north_id: ante_chamber.id})
|> Repo.update

{:ok, starting_save} = %Config{}
|> Config.changeset(%{name: "starting_save", value: %{room_id: hallway.id} |> Poison.encode!})
|> Repo.insert

{:ok, _} = %User{}
|> User.changeset(%{username: "eric", password: "password", save: Config.starting_save()})
|> Repo.insert
