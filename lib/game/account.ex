defmodule Game.Account do
  @moduledoc """
  Handle database interactions for a user
  """

  alias Data.Repo
  alias Data.Config
  alias Data.User

  @doc """
  Create a new user from attributes
  """
  @spec create(attributes :: Map.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def create(attributes) do
    attributes = attributes
    |> Map.put(:save, Config.starting_save())

    %User{}
    |> User.changeset(attributes)
    |> Repo.insert
  end

  @doc """
  Update the user's save
  """
  @spec save(user :: User.t, save :: Save.t) :: {:ok, User.t} | {:error, Ecto.Changeset.t}
  def save(user, save) do
    user
    |> User.changeset(%{save: save})
    |> Repo.update
  end
end
