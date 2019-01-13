defmodule Web.Character do
  @moduledoc """
  Web context for characters
  """

  import Ecto.Query

  alias Data.Character
  alias Data.QuestProgress
  alias Data.Repo
  alias Data.Stats
  alias Game.Account
  alias Game.Config
  alias Game.Session
  alias Game.Session.Registry, as: SessionRegistry
  alias Metrics.PlayerInstrumenter
  alias Web.Filter
  alias Web.Pagination
  alias Web.Race
  alias Web.User

  @behaviour Filter

  @doc """
  Load all characters
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Character
    |> order_by([c], desc: c.updated_at)
    |> preload([:class, :race, :user])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"level_from", level}, query) do
    query
    |> where([c], fragment("?->>'level' >= ?", c.save, ^to_string(level)))
  end

  def filter_on_attribute({"level_to", level}, query) do
    query
    |> where([c], fragment("?->>'level' <= ?", c.save, ^to_string(level)))
  end

  def filter_on_attribute({"name", name}, query) do
    query
    |> where([c], ilike(c.name, ^"%#{name}%"))
  end

  def filter_on_attribute({"class_id", class_id}, query) do
    query
    |> where([c], c.class_id == ^class_id)
  end

  def filter_on_attribute({"race_id", race_id}, query) do
    query
    |> where([c], c.race_id == ^race_id)
  end

  def filter_on_attribute(_, query), do: query

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
  def get(character_id) do
    case Repo.get_by(Character, id: character_id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, Repo.preload(character, [:class, :race, :user, quest_progress: [:quest]])}
    end
  end

  def new(), do: %Character{} |> Character.changeset(%{})

  @doc """
  Create a new character for a user
  """
  def create(user, params) do
    save = starting_save(params)
    params = Map.put(params, "save", save)

    PlayerInstrumenter.new_character()

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

  @doc """
  Disconnect players

  The server will shutdown shortly.
  """
  @spec disconnect() :: :ok
  def disconnect() do
    SessionRegistry.connected_players()
    |> Enum.each(fn %{pid: pid} ->
      Session.disconnect(pid, reason: "server shutdown", force: true)
    end)

    :ok
  end

  @spec disconnect(integer()) :: :ok
  def disconnect(user_id) do
    case Session.find_connected_player(user_id) do
      nil ->
        :ok

      %{pid: pid} ->
        Session.disconnect(pid, reason: "disconnect", force: true)
        :ok
    end
  end

  @doc """
  Teleport a user to the room

  Updates the save and sends a message to their session
  """
  def teleport(character, room_id) do
    room_id = String.to_integer(room_id)
    save = %{character.save | room_id: room_id}
    changeset = character |> Character.changeset(%{save: save})

    case changeset |> Repo.update() do
      {:ok, character} ->
        teleport_player_in_game(character, room_id)

        {:ok, character}

      anything ->
        anything
    end
  end

  def teleport_player_in_game(character, room_id) do
    case SessionRegistry.find_connected_player(character.id) do
      nil ->
        nil

      %{pid: pid} ->
        pid |> Session.teleport(room_id)
    end
  end

  @doc """
  Reset a player's save file, and quest progress
  """
  def reset(character_id) do
    with {:ok, character} <- get(character_id) do
      QuestProgress
      |> where([qp], qp.character_id == ^character.id)
      |> Repo.delete_all()

      Account.save(character, starting_save(%{"race_id" => character.race_id}))
    end

    :ok
  end
end
