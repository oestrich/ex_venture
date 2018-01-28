defmodule Web.User do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.QuestProgress
  alias Data.Repo
  alias Data.Stats
  alias Data.User
  alias Game.Account
  alias Game.Authentication
  alias Game.Config
  alias Game.Session
  alias Game.Session.Registry, as: SessionRegistry
  alias Web.Filter
  alias Web.Pagination
  alias Web.Race

  @behaviour Filter

  @doc """
  Fetch a user from a web token
  """
  @spec from_token(token :: String.t()) :: User.t()
  def from_token(token) do
    User
    |> where([u], u.token == ^token)
    |> Repo.one()
  end

  @doc """
  Load all users
  """
  @spec all(opts :: Keyword.t()) :: [User.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    User
    |> order_by([u], asc: u.level)
    |> preload([:class, :race])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"level_from", level}, query) do
    query
    |> where([u], fragment("?->>'level' >= ?", u.save, ^to_string(level)))
  end

  def filter_on_attribute({"level_to", level}, query) do
    query
    |> where([u], fragment("?->>'level' <= ?", u.save, ^to_string(level)))
  end

  def filter_on_attribute({"class_id", class_id}, query) do
    query
    |> where([u], u.class_id == ^class_id)
  end

  def filter_on_attribute({"race_id", race_id}, query) do
    query
    |> where([u], u.race_id == ^race_id)
  end

  def filter_on_attribute(_, query), do: query

  @doc """
  Load a user
  """
  @spec get(id :: integer) :: User.t()
  def get(id) do
    User
    |> where([u], u.id == ^id)
    |> preload([
      :class,
      :race,
      sessions: ^from(s in User.Session, order_by: [desc: s.started_at], limit: 10)
    ])
    |> preload(quest_progress: [:quest])
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %User{} |> User.changeset(%{})

  @doc """
  Create a new user
  """
  @spec create(params :: map) :: {:ok, User.t()} | {:error, changeset :: map}
  def create(params = %{"race_id" => race_id}) do
    save = starting_save(race_id)
    params = Map.put(params, "save", save)

    changeset = %User{} |> User.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, user} ->
        Account.maybe_email_welcome(user)

        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Get a starting save for a user
  """
  @spec starting_save(race_id :: integer()) :: Save.t()
  def starting_save(race_id) do
    race = Race.get(race_id)

    Config.starting_save()
    |> Map.put(:stats, race.starting_stats() |> Stats.default())
  end

  @doc """
  List out connected players
  """
  @spec connected_players() :: [User.t()]
  def connected_players() do
    SessionRegistry.connected_players()
    |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Teleport a user to the room

  Updates the save and sends a message to their session
  """
  @spec teleport(user :: User.t(), room_id :: integer) :: {:ok, User.t()} | {:error, map}
  def teleport(user, room_id) do
    room_id = String.to_integer(room_id)
    save = %{user.save | room_id: room_id}
    changeset = user |> User.changeset(%{save: save})

    case changeset |> Repo.update() do
      {:ok, user} ->
        teleport_player_in_game(user, room_id)

        {:ok, user}

      anything ->
        anything
    end
  end

  def teleport_player_in_game(user, room_id) do
    player =
      SessionRegistry.connected_players()
      |> Enum.find(fn {_, player} -> player.id == user.id end)

    case player do
      nil -> nil
      {pid, _} -> pid |> Session.teleport(room_id)
    end
  end

  @doc """
  Reset a player's save file, and quest progress
  """
  def reset(user_id) do
    user = Repo.get(User, user_id)

    QuestProgress
    |> where([qp], qp.user_id == ^user.id)
    |> Repo.delete_all()

    Account.save(user, starting_save(user.race_id))
  end

  @doc """
  Change a user's password
  """
  @spec change_password(user :: User.t(), current_password :: String.t(), params :: map) ::
          {:ok, User.t()}
  def change_password(user, current_password, params) do
    case Authentication.find_and_validate(user.name, current_password) do
      {:error, :invalid} ->
        {:error, :invalid}

      user ->
        user
        |> User.password_changeset(params)
        |> Repo.update()
    end
  end

  @doc """
  Disconnect players

  The server will shutdown shortly.
  """
  @spec disconnect() :: :ok
  def disconnect() do
    SessionRegistry.connected_players()
    |> Enum.each(fn {session, _} ->
      Session.disconnect(session, force: true)
    end)

    :ok
  end
end
