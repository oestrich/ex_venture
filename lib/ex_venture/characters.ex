defmodule ExVenture.Characters.Character do
  @moduledoc """
  Schema for a character controlled by a player
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Users.User

  schema "characters" do
    field(:name, :string)

    belongs_to(:user, User)

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name, :user_id])
    |> foreign_key_constraint(:user_id)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end

defmodule ExVenture.Characters do
  @moduledoc """
  Characters are controlled by players to act inside of the game
  """

  import Ecto.Query

  alias ExVenture.Characters.Character
  alias ExVenture.Repo

  @doc """
  Get all characters for a user
  """
  def all_for(user) do
    Character
    |> where([c], c.user_id == ^user.id)
    |> Repo.all()
  end

  @doc """
  Get a character scoped to the user accessing it
  """
  def get(id) do
    case Repo.get(Character, id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, character}
    end
  end

  @doc """
  Get a character scoped to the user accessing it
  """
  def get(user, id) do
    case Repo.get_by(Character, id: id, user_id: user.id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, character}
    end
  end

  @doc """
  Create a new character for a user
  """
  def create(user, params) do
    user
    |> Ecto.build_assoc(:characters)
    |> Character.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update basic information about a character
  """
  def update(character, params) do
    character
    |> Character.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Delete a character for a user
  """
  def delete(character) do
    Repo.delete(character)
  end
end
