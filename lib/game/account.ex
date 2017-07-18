defmodule Game.Account do
  alias Data.Repo
  alias Data.Config
  alias Data.User

  def create(attributes) do
    attributes = attributes
    |> Map.put(:save, Config.starting_save())

    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end

  def save(user, save) do
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end
end
