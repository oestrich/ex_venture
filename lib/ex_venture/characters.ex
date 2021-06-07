defmodule ExVenture.Characters.Character do
  @moduledoc """
  Schema for a character controlled by a player
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Characters.PlayableCharacter

  schema "characters" do
    field(:name, :string)

    has_many(:playable, PlayableCharacter)

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end

defmodule ExVenture.Characters do
  @moduledoc """
  Characters are controlled by players to act inside of the game
  """

  import Ecto.Query

  alias ExVenture.Characters.Character
  alias ExVenture.Characters.PlayableCharacter
  alias ExVenture.Repo

  @doc """
  Get all characters for a user
  """
  def all_for(user) do
    Character
    |> join(:left, [c], pc in assoc(c, :playable))
    |> where([c, pc], pc.user_id == ^user.id)
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
    query =
      Character
      |> join(:left, [c], pc in assoc(c, :playable))
      |> where([c, pc], c.id == ^id and pc.user_id == ^user.id)
      |> limit(1)

    case Repo.one(query) do
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
    changeset = Character.create_changeset(%Character{}, params)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:character, changeset)
      |> Ecto.Multi.insert(:playable_character, fn %{character: character} ->
        user
        |> Ecto.build_assoc(:playable_characters)
        |> PlayableCharacter.create_changeset(character)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{character: character}} ->
        {:ok, character}

      {:error, :character, changeset, _changeset} ->
        {:error, changeset}
    end
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
    query =
      PlayableCharacter
      |> where([pc], pc.character_id == ^character.id)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:playable_characters, query)
    |> Ecto.Multi.delete(:character, character)
    |> Repo.transaction()
  end
end
