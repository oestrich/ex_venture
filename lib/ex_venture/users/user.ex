defmodule ExVenture.Users.User do
  @moduledoc """
  User schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field(:token, Ecto.UUID)

    field(:role, :string)

    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)

    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)

    field(:email_verification_token, Ecto.UUID)
    field(:email_verified_at, :utc_datetime)

    field(:password_reset_token, Ecto.UUID)
    field(:password_reset_expires_at, :utc_datetime)

    field(:avatar_key, Ecto.UUID)
    field(:avatar_extension, :string)

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:email, :first_name, :last_name, :password, :password_confirmation])
    |> put_change(:token, UUID.uuid4())
    |> validate_confirmation(:password)
    |> Stein.Accounts.hash_password()
    |> Stein.Accounts.start_email_verification_changeset()
    |> validate_required([:email, :first_name, :last_name, :password_hash])
    |> unique_constraint(:email, name: :users_lower_email_index)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:email, :first_name, :last_name])
    |> validate_required([:email, :first_name, :last_name])
    |> unique_constraint(:email, name: :users_lower_email_index)
    |> maybe_restart_email_verification()
  end

  def password_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> Stein.Accounts.hash_password()
  end

  def avatar_changeset(struct, key, extension) do
    struct
    |> change()
    |> put_change(:avatar_key, key)
    |> put_change(:avatar_extension, extension)
  end

  defp maybe_restart_email_verification(changeset) do
    case is_nil(get_change(changeset, :email)) do
      true ->
        changeset

      false ->
        changeset
        |> Stein.Accounts.start_email_verification_changeset()
        |> put_change(:email_verified_at, nil)
    end
  end
end
