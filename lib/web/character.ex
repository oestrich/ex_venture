defmodule Web.Character do
  @moduledoc """
  Web context for characters
  """

  alias Data.Character
  alias Data.Repo
  alias Data.Stats
  alias Game.Account
  alias Game.Config
  alias Web.Race
  alias Web.User

  @doc """
  Get a character by their name
  """
  @spec get_character_by(Keyword.t()) :: {:ok, User.t()} | {:error, :not_found}
  def get_character_by(name: name) do
    case Repo.get_by(Character, name: name) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, user}
    end
  end

  @doc """
  Get a user's character
  """
  def get_character(user, character_id) do
    case Repo.get_by(Character, user_id: user.id, id: character_id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, character}
    end
  end

  @doc """
  Get a character

  Used from the socket and channels
  """
  def get_character(character_id) do
    case Repo.get_by(Character, id: character_id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, character}
    end
  end

  def new(), do: %Character{} |> Character.changeset(%{})

  @doc """
  Create a new character for a user
  """
  def create(user, params) do
    save = starting_save(params)
    params = Map.put(params, "save", save)

    user
    |> Ecto.build_assoc(:characters)
    |> Character.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Get a starting save for a character
  """
  @spec starting_save(map()) :: Save.t()
  def starting_save(params) do
    with {:ok, race_id} <- Map.fetch(params, "race_id") do
      race = Race.get(race_id)

      Config.starting_save()
      |> Map.put(:stats, race.starting_stats() |> Stats.default())
      |> Account.maybe_change_starting_room()
    else 
      _ ->
        nil
    end
  end
end
