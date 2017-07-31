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

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :password, :save])
    |> validate_required([:name])
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
end
