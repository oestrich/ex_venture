defmodule Data.User do
  @moduledoc """
  User schema
  """

  use Data.Schema

  alias Data.Save

  schema "users" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :save, Data.Save
    field :flags, {:array, :string}
    field :token, Ecto.UUID

    belongs_to :class, Data.Class

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :password, :save, :flags, :class_id])
    |> validate_required([:name, :save, :class_id])
    |> validate_save()
    |> validate_name()
    |> ensure_flags()
    |> ensure_token()
    |> hash_password
    |> validate_required([:password_hash])
    |> unique_constraint(:name)
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
      _ -> changeset
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
      _ -> changeset
    end
  end

  defp ensure_flags(changeset) do
    case changeset do
      %{changes: %{flags: _ids}} -> changeset
      %{data: %{flags: ids}} when ids != nil -> changeset
      _ -> put_change(changeset, :flags, [])
    end
  end

  defp ensure_token(changeset) do
    case changeset do
      %{changes: %{token: _token}} -> changeset
      %{data: %{token: token}} when token != nil -> changeset
      _ -> put_change(changeset, :token, UUID.uuid4())
    end
  end
end
