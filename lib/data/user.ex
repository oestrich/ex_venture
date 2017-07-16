defmodule Data.User do
  use Data.Schema

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :save, Data.Save

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:username, :password, :save])
    |> validate_required([:username])
    |> hash_password
    |> validate_required([:password_hash])
    |> unique_constraint(:username)
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
