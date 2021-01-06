{:ok, _api_token} =
  ExVenture.APIKeys.create(%{
    token: "6e8d83d9-a028-4eb7-bc7b-9b32bac697b6",
    is_active: true
  })

{:ok, _user} =
  ExVenture.Users.create(%{
    username: "user",
    email: "user@example.com",
    password: "password",
    password_confirmation: "password"
  })

{:ok, admin} =
  ExVenture.Users.create(%{
    username: "admin",
    email: "admin@example.com",
    password: "password",
    password_confirmation: "password"
  })

{:ok, _admin} =
  admin
  |> Ecto.Changeset.change(%{role: "admin"})
  |> ExVenture.Repo.update()

#
# The World
#

{:ok, sammatti} =
  ExVenture.Zones.create(%{
    name: "Sammatti",
    description: "The starter town."
  })

{:ok, sammatti} = ExVenture.Zones.publish(sammatti)

{:ok, town_square} =
  ExVenture.Rooms.create(sammatti, %{
    name: "Town Square",
    description: "A small town square.",
    listen: "The town crier is telling the latest news.",
    map_icon: "wooden-sign",
    x: 0,
    y: 0,
    z: 0
  })

{:ok, _town_square} = ExVenture.Rooms.publish(town_square)

{:ok, market} =
  ExVenture.Rooms.create(sammatti, %{
    name: "Market",
    description: "A small market.",
    listen: "Shop keeps are selling their wares.",
    map_icon: "shop",
    x: 0,
    y: 1,
    z: 0
  })

{:ok, _market} = ExVenture.Rooms.publish(market)
