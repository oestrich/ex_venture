{:ok, _user} =
  ExVenture.Users.create(%{
    email: "user@example.com",
    first_name: "User",
    last_name: "Example",
    password: "password",
    password_confirmation: "password"
  })
