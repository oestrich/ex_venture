defmodule Web.User do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  require Logger

  alias Data.Repo
  alias Data.User
  alias Data.User.OneTimePassword
  alias ExVenture.Mailer
  alias Game.Account
  alias Game.Config
  alias Game.Emails
  alias Game.Session.Registry, as: SessionRegistry
  alias Metrics.PlayerInstrumenter
  alias Web.Character
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  User flags
  """
  @spec flags() :: [String.t()]
  def flags(), do: ["admin", "builder", "disabled"]

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
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"name", name}, query) do
    query
    |> where([u], ilike(u.name, ^"%#{name}%"))
  end

  def filter_on_attribute(_, query), do: query

  @doc """
  Load a user
  """
  @spec get(id :: integer) :: User.t()
  def get(id) do
    User
    |> where([u], u.id == ^id)
    |> preload(sessions: ^from(s in User.Session, order_by: [desc: s.started_at], limit: 10))
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
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %User{} |> User.create_changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(User.t()) :: changeset :: map
  def edit(user), do: user |> User.update_changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec email_changeset(User.t()) :: map()
  def email_changeset(user), do: user |> User.email_changeset(%{})

  @doc """
  Get a changeset for finalizing registration
  """
  def finalize(user), do: user |> User.finalize_changeset(%{})

  @doc """
  Create a new user
  """
  @spec create(params :: map) :: {:ok, User.t()} | {:error, changeset :: map}
  def create(params) do
    case Repo.transaction(fn -> _create(params) end) do
      {:ok, result} ->
        result

      {:error, result} ->
        result
    end
  end

  def _create(params) do
    with {:ok, user} <- create_user(params) do
      case Character.create(user, params) do
        {:ok, character} ->
          Account.maybe_email_welcome(user)

          Config.claim_character_name(character.name)

          {:ok, user, character}

        {:error, changeset} ->
          user_changeset =
            user
            |> Ecto.Changeset.change()
            |> Map.put(:action, :insert)
            |> Map.put(:errors, changeset.errors)

          Repo.rollback({:error, user_changeset})
      end
    else
      {:error, changeset} ->
        Repo.rollback({:error, changeset})
    end
  end

  defp create_user(params) do
    %User{}
    |> User.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a user
  """
  @spec update(integer(), map()) :: {:ok, User.t()} | {:error, changeset :: map}
  def update(id, params) do
    user = get(id)

    case is_nil(user.provider) do
      true ->
        user
        |> User.update_changeset(cast_params(params))
        |> Repo.update()

      false ->
        user
        |> User.edit_changeset(cast_params(params))
        |> Repo.update()
    end
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
  Finalize a user
  """
  @spec finalize_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def finalize_user(user, params) do
    user
    |> User.finalize_changeset(params)
    |> Repo.update()
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
    Bcrypt.no_user_verify()
    {:error, :invalid}
  end

  defp _find_and_validate(%{password_hash: nil}, _password) do
    Bcrypt.no_user_verify()
    {:error, :invalid}
  end

  defp _find_and_validate(user, password) do
    case Bcrypt.verify_pass(password, user.password_hash) do
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

  @doc """
  Authorize a connection
  """
  @spec authorize_connection(Data.Character.t(), String.t()) :: :ok
  def authorize_connection(character, id) do
    SessionRegistry.authorize_connection(character, id)
  end

  @doc """
  True if the user needs to be finalized and finish registration
  """
  def finalize_registration?(user) do
    is_nil(user.name)
  end

  @doc """
  Find or create a user who signed in from Grapevine
  """
  def from_grapevine(auth) do
    params = %{
      provider: to_string(auth.provider),
      provider_uid: auth.uid,
      name: auth.info.name,
      email: auth.info.email
    }

    auth
    |> maybe_find_user()
    |> maybe_fully_register(params)
    |> maybe_partially_register(params)
  end

  defp maybe_find_user(auth) do
    provider = to_string(auth.provider)

    case Repo.get_by(User, provider: provider, provider_uid: auth.uid) do
      nil ->
        {:error, :not_found}

      user ->
        case is_nil(user.name) do
          true ->
            {:ok, :finalize_registration, user}

          false ->
            {:ok, user}
        end
    end
  end

  defp maybe_fully_register({:ok, user}, _params), do: {:ok, user}

  defp maybe_fully_register({:ok, :finalize_registration, user}, _params),
    do: {:ok, :finalize_registration, user}

  defp maybe_fully_register({:error, :not_found}, params) do
    %User{}
    |> User.grapevine_changeset(params)
    |> Repo.insert()
  end

  defp maybe_partially_register({:ok, user}, _params), do: {:ok, user}

  defp maybe_partially_register({:ok, :finalize_registration, user}, _params),
    do: {:ok, :finalize_registration, user}

  defp maybe_partially_register({:error, _changeset}, params) do
    params =
      params
      |> Map.delete(:email)
      |> Map.delete(:name)

    changeset = %User{} |> User.grapevine_changeset(params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, :finalize_registration, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
