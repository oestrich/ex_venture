defmodule Data.User do
  @moduledoc """
  User schema
  """

  use Data.Schema

  alias Data.Save

  @type t :: %{
    name: String.t,
    save: Save.t,
  }

  schema "users" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :save, Data.Save
    field :flags, {:array, :string}

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :password, :save, :flags])
    |> validate_required([:name, :save])
    |> validate_save()
    |> ensure_flags()
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

  defp ensure_flags(changeset) do
    case changeset do
      %{changes: %{flags: _ids}} -> changeset
      %{data: %{flags: ids}} when ids != nil -> changeset
      _ -> put_change(changeset, :flags, [])
    end
  end
end
