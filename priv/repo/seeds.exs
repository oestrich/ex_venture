alias Data.Repo
alias Data.Room
alias Data.User

{:ok, _} = %User{}
|> User.changeset(%{username: "eric", password: "password"})
|> Repo.insert

{:ok, hallway} = %Room{}
|> Room.changeset(%{name: "Hallway", description: "An empty hallway"})
|> Repo.insert

{:ok, ante_chamber} = %Room{}
|> Room.changeset(%{name: "Ante Chamber", description: "The Ante-Chamber", south_id: hallway.id})
|> Repo.insert

{:ok, hallway} = hallway
|> Room.changeset(%{north_id: ante_chamber.id})
|> Repo.update
