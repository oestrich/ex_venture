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
    field :seconds_online, :integer

    belongs_to :class, Data.Class

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :password, :save, :flags, :class_id, :seconds_online])
    |> validate_required([:name, :save, :class_id])
    |> validate_save()
    |> validate_name()
    |> ensure(:flags, [])
    |> ensure(:token, UUID.uuid4())
    |> ensure(:seconds_online, 0)
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

  defp ensure(changeset, field, default) do
    case changeset do
      %{changes: %{^field => _ids}} -> changeset
      %{data: %{^field => ids}} when ids != nil -> changeset
      _ -> put_change(changeset, field, default)
    end
  end
end
