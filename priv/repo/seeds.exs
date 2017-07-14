alias Data.Repo
alias Data.User

{:ok, _} = %User{}
|> User.changeset(%{username: "eric", password: "password"})
|> Repo.insert
