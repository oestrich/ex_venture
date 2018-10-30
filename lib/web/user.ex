defmodule Web.User do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  require Logger

  alias Data.Character
  alias Data.QuestProgress
  alias Data.Repo
  alias Data.Stats
  alias Data.User
  alias Data.User.OneTimePassword
  alias ExVenture.Mailer
  alias Game.Account
  alias Game.Config
  alias Game.Emails
  alias Game.Experience
  alias Game.Session
  alias Game.Session.Registry, as: SessionRegistry
  alias Metrics.PlayerInstrumenter
  alias Web.Filter
  alias Web.Pagination
  alias Web.Race

  @behaviour Filter

  @doc """
  User flags
  """
  @spec flags() :: [String.t()]
  def flags(), do: ["admin", "disabled"]

  @doc """
  Check if a player is disabled
  """
  def disabled?(player) do
    "disabled" in player.flags
  end

  @doc """
  Fetch a user from a web token
  """
  @spec from_token(token :: String.t()) :: User.t()
  def from_token(token) do
    User
    |> where([u], u.token == ^token)
    |> preload([:characters])
    |> Repo.one()
  end

  @doc """
  Load all users
  """
  @spec all(opts :: Keyword.t()) :: [User.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    User
    |> order_by([u], desc: u.updated_at)
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

  def filter_on_attribute({"name", name}, query) do
    query
    |> where([u], ilike(u.name, ^"%#{name}%"))
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
    |> preload(characters: [quest_progress: [:quest]])
    |> Repo.one()
  end

  @doc """
  Get a user by their name
  """
  @spec get_by(Keyword.t()) :: {:ok, User.t()} | {:error, :not_found}
  def get_by(name: name) do
    case Repo.get_by(User, name: name) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, user}
    end
  end

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

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %User{} |> User.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(User.t()) :: changeset :: map
  def edit(user), do: user |> User.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec email_changeset(User.t()) :: map()
  def email_changeset(user), do: user |> User.email_changeset(%{})

  @doc """
  Create a new user
  """
  @spec create(params :: map) :: {:ok, User.t()} | {:error, changeset :: map}
  def create(params = %{"race_id" => _race_id}) do
    result = Repo.transaction(fn -> _create(params) end)

    case result do
      {:ok, result} ->
        result

      {:error, result} ->
        result
    end
  end

  def create(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  def _create(params = %{"race_id" => race_id}) do
    with {:ok, user} <- create_user(race_id, params),
         {:ok, character} <- create_character(user, race_id, params) do
      Account.maybe_email_welcome(user)

      Config.claim_character_name(character.name)

      {:ok, user, character}
    else
      {:error, changeset} ->
        Repo.rollback(changeset)
    end
  end

  defp create_user(race_id, params) do
    save = starting_save(race_id)
    params = Map.put(params, "save", save)

    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  defp create_character(user, race_id, params) do
    save = starting_save(race_id)
    params = Map.put(params, "save", save)

    user
    |> Ecto.build_assoc(:characters)
    |> Character.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a user
  """
  @spec update(integer(), map()) :: {:ok, User.t()} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> User.changeset(cast_params(params))
    |> Repo.update()
  end

  defp cast_params(params) do
    case Map.has_key?(params, "flags") do
      true ->
        flags =
          params
          |> Map.get("flags")
          |> Enum.reject(&(&1 == ""))

        Map.put(params, "flags", flags)

      false ->
        params
    end
  end

  @doc """
  Get a starting save for a user
  """
  @spec starting_save(race_id :: integer()) :: Save.t()
  def starting_save(race_id) do
    race = Race.get(race_id)

    Config.starting_save()
    |> Map.put(:stats, race.starting_stats() |> Stats.default())
    |> Account.maybe_change_starting_room()
  end

  @doc """
  List out connected players
  """
  @spec connected_players() :: [User.t()]
  def connected_players() do
    SessionRegistry.connected_players()
    |> Enum.map(& &1.player)
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
    case SessionRegistry.find_connected_player(user.id) do
      nil ->
        nil

      %{pid: pid} ->
        pid |> Session.teleport(room_id)
    end
  end

  @doc """
  Reset a player's save file, and quest progress
  """
  def reset(user_id) do
    user =
      User
      |> Repo.get(user_id)
      |> Repo.preload([:characters])

    Enum.each(user.characters, fn character ->
      QuestProgress
      |> where([qp], qp.character_id == ^character.id)
      |> Repo.delete_all()

      Account.save(character, starting_save(character.race_id))
    end)

    :ok
  end

  @doc """
  Change a user's password
  """
  @spec change_password(user :: User.t(), current_password :: String.t(), params :: map) ::
          {:ok, User.t()}
  def change_password(user, current_password, params) do
    case find_and_validate(user.name, current_password) do
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
  Start the TOTP validation
  """
  @spec create_totp_secret(User.t()) :: {:ok, OneTimePassword.t()}
  def create_totp_secret(user) do
    case {user.totp_secret, user.totp_verified_at} do
      {secret, nil} when secret != nil ->
        user

      _ ->
        user
        |> User.totp_changeset()
        |> Repo.update!()
    end
  end

  @doc """
  The token was verified and TOTP should be turned on
  """
  @spec totp_token_verified(User.t()) :: {:ok, OneTimePassword.t()}
  def totp_token_verified(user) do
    user
    |> User.totp_verified_changeset()
    |> Repo.update!()
  end

  @doc """
  Clear the user's TOTP state
  """
  @spec reset_totp(User.t()) :: {:ok, OneTimePassword.t()}
  def reset_totp(user) do
    user
    |> User.totp_reset_changeset()
    |> Repo.update!()
  end

  def generate_qr_png(user) do
    secret = Base.encode32(Base.decode32!(user.totp_secret), padding: false)
    issuer = URI.encode(Config.game_name())
    url = "otpauth://totp/#{issuer}:#{user.name}?secret=#{secret}&issuer=#{issuer}"

    url
    |> EQRCode.encode()
    |> EQRCode.png()
  end

  @doc """
  Check the TOTP token against the user
  """
  @spec valid_totp_token?(User.t(), String.t()) :: boolean()
  def valid_totp_token?(user, token) do
    secret = Base.encode32(Base.decode32!(user.totp_secret, padding: false))
    :pot.valid_totp(token, secret)
  end

  @doc """
  Check if the user has TOTP on and verified
  """
  @spec totp_verified?(User.t()) :: boolean()
  def totp_verified?(user) do
    !!user.totp_secret && !!user.totp_verified_at
  end

  @doc """
  Attempt to find a user and validate their password
  """
  @spec find_and_validate(String.t(), String.t()) :: {:error, :invalid} | User.t()
  def find_and_validate(name, password) do
    User
    |> where([u], ilike(u.name, ^name))
    |> Repo.one()
    |> _find_and_validate(password)
  end

  defp _find_and_validate(nil, _password) do
    Comeonin.Bcrypt.dummy_checkpw()
    {:error, :invalid}
  end

  defp _find_and_validate(user, password) do
    case Comeonin.Bcrypt.checkpw(password, user.password_hash) do
      true ->
        user

      _ ->
        {:error, :invalid}
    end
  end

  @doc """
  Start password reset
  """
  @spec start_password_reset(String.t()) :: :ok
  def start_password_reset(email) do
    PlayerInstrumenter.start_password_reset()

    query = User |> where([u], u.email == ^email)

    case query |> Repo.one() do
      nil ->
        Logger.warn("Password reset attempted for #{email}")

        :ok

      user ->
        Logger.info("Starting password reset for #{user.email}")

        user
        |> User.password_reset_changeset()
        |> Repo.update!()
        |> Emails.password_reset()
        |> Mailer.deliver_now()

        :ok
    end
  end

  @doc """
  Reset a password
  """
  @spec reset_password(String.t(), map()) :: {:ok, User.t()}
  def reset_password(token, params) do
    PlayerInstrumenter.password_reset()

    with {:ok, uuid} <- Ecto.UUID.cast(token),
         {:ok, user} <- find_user_by_reset_token(uuid),
         {:ok, user} <- check_password_reset_expired(user) do
      user
      |> User.password_changeset(params)
      |> Repo.update()
    end
  end

  defp find_user_by_reset_token(uuid) do
    query = User |> where([u], u.password_reset_token == ^uuid)

    case query |> Repo.one() do
      nil ->
        :error

      user ->
        {:ok, user}
    end
  end

  defp check_password_reset_expired(user) do
    case Timex.after?(Timex.now(), user.password_reset_expires_at) do
      true ->
        :error

      false ->
        {:ok, user}
    end
  end

  @doc """
  Reset a password
  """
  @spec change_email(User.t(), map()) :: {:ok, User.t()}
  def change_email(user, params) do
    user
    |> User.email_changeset(params)
    |> Repo.update()
  end

  def activate_cheat(user, params) do
    case Map.get(params, "name") do
      "experience" ->
        experience_points = String.to_integer(Map.get(params, "value"))
        save = Experience.add_experience(user.save, experience_points)
        save = Experience.maybe_level_up(user.save, save)
        Account.save(user, save)
    end
  end

  @doc """
  Authorize a connection
  """
  @spec authorize_connection(User.t(), String.t()) :: :ok
  def authorize_connection(user, id) do
    SessionRegistry.authorize_connection(user, id)
  end
end
