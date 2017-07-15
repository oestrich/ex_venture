defmodule Game.Account do
  alias Data.Repo
  alias Data.User

  def create(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end
end
