defmodule Data.User do
  @moduledoc """
  User schema
  """

  use Data.Schema

  alias Data.Class
  alias Data.QuestProgress
  alias Data.Race
  alias Data.Save
  alias Data.User.OneTimePassword
  alias Data.User.Session

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:save, Data.Save)
    field(:flags, {:array, :string})
    field(:token, Ecto.UUID)
    field(:seconds_online, :integer)

    belongs_to(:class, Class)
    belongs_to(:race, Race)

    has_many(:sessions, Session)
    has_many(:quest_progress, QuestProgress)
    has_many(:one_time_passwords, OneTimePassword)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :email,
      :password,
      :save,
      :flags,
      :race_id,
      :class_id,
      :seconds_online
    ])
    |> validate_required([:name, :save, :race_id, :class_id])
    |> validate_save()
    |> validate_name()
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> ensure(:flags, [])
    |> ensure(:token, UUID.uuid4())
    |> ensure(:seconds_online, 0)
    |> hash_password
    |> validate_required([:password_hash])
    |> validate_confirmation(:password)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:class_id)
  end

  def password_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_confirmation(:password)
    |> hash_password
    |> validate_required([:password_hash])
  end

  defp hash_password(changeset) do
    case changeset do
      %{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  defp validate_save(changeset) do
    case changeset do
      %{changes: %{save: save}} when save != nil ->
        _validate_save(changeset)

      _ ->
        changeset
    end
  end

  defp _validate_save(changeset = %{changes: %{save: save}}) do
    case Save.valid?(save) do
      true -> changeset
      false -> add_error(changeset, :save, "is invalid")
    end
  end

  defp validate_name(changeset) do
    case changeset do
      %{changes: %{name: name}} ->
        case Regex.match?(~r/ /, name) do
          true -> add_error(changeset, :name, "cannot contain spaces")
          false -> changeset
        end

      _ ->
        changeset
    end
  end
end
