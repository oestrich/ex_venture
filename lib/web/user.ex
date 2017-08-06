defmodule Web.User do
  import Ecto.Query

  alias Data.User
  alias Data.Repo

  def from_token(token) do
    User
    |> where([u], u.token == ^token)
    |> Repo.one
  end
end
