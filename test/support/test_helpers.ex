defmodule TestHelpers do
  alias Data.Repo
  alias Data.User

  def create_user(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert!
  end
end
