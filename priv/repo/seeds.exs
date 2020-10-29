{:ok, _user} =
  ExVenture.Users.create(%{
    email: "user@example.com",
    first_name: "User",
    last_name: "Example",
    password: "password",
    password_confirmation: "password"
  })

{:ok, admin} =
  ExVenture.Users.create(%{
    email: "admin@example.com",
    first_name: "Admin",
    last_name: "Example",
    password: "password",
    password_confirmation: "password"
  })

{:ok, _admin} =
  admin
  |> Ecto.Changeset.change(%{role: "admin"})
  |> ExVenture.Repo.update()
