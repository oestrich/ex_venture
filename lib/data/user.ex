defmodule Data.User do
  @moduledoc """
  User schema
  """

  use Data.Schema

  alias Data.Character
  alias Data.User.Session

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:flags, {:array, :string})
    field(:token, Ecto.UUID)
    field(:notes, :string)

    field(:provider, :string)
    field(:provider_uid, :string)

    field(:totp_secret, :string)
    field(:totp_verified_at, :utc_datetime_usec)

    field(:password_reset_token, Ecto.UUID)
    field(:password_reset_expires_at, :utc_datetime_usec)

    has_many(:characters, Character)
    has_many(:sessions, Session)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Check if a user is an admin
  """
  def is_admin?(user) do
    "admin" in user.flags
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :email,
      :password,
      :password_confirmation,
      :flags,
      :notes
    ])
    |> validate_required([:name])
    |> validate_name()
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> ensure(:flags, [])
    |> ensure(:token, UUID.uuid4())
    |> hash_password()
    |> validate_required([:password_hash])
    |> validate_confirmation(:password)
    |> unique_constraint(:name, name: :users_lower_name_index)
    |> unique_constraint(:email)
  end

  def grapevine_changeset(struct, params) do
    struct
    |> cast(params, [:name, :email, :provider, :provider_uid])
    |> validate_required([:provider, :provider_uid])
    |> validate_name()
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> ensure(:flags, [])
    |> ensure(:token, UUID.uuid4())
    |> unique_constraint(:name, name: :users_lower_name_index)
    |> unique_constraint(:email)
    |> unique_constraint(:provider_uid, name: :users_provider_provider_uid_index)
  end

  def finalize_changeset(struct, params) do
    struct
    |> cast(params, [:name, :email])
    |> validate_required([:name])
    |> validate_name()
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> unique_constraint(:name, name: :users_lower_name_index)
    |> unique_constraint(:email)
  end

  def email_changeset(struct, params) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  def password_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_confirmation(:password)
    |> put_change(:password_reset_token, nil)
    |> put_change(:password_reset_expires_at, nil)
    |> hash_password
    |> validate_required([:password_hash])
  end

  def password_reset_changeset(struct) do
    struct
    |> change()
    |> put_change(:password_reset_token, UUID.uuid4())
    |> put_change(:password_reset_expires_at, Timex.now() |> Timex.shift(hours: 1))
  end

  def totp_changeset(struct) do
    struct
    |> change()
    |> put_change(:totp_secret, Base.encode32(:crypto.strong_rand_bytes(8)))
    |> put_change(:totp_verified_at, nil)
  end

  def totp_verified_changeset(struct) do
    struct
    |> change()
    |> put_change(:totp_verified_at, Timex.now())
  end

  def totp_reset_changeset(struct) do
    struct
    |> change()
    |> put_change(:totp_secret, nil)
    |> put_change(:totp_verified_at, nil)
  end

  defp hash_password(changeset) do
    case changeset do
      %{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  defp validate_name(changeset) do
    case changeset do
      %{changes: %{name: name}} ->
        case Regex.match?(~r/ /, name) do
          true ->
            add_error(changeset, :name, "cannot contain spaces")

          false ->
            changeset
        end

      _ ->
        changeset
    end
  end
end
