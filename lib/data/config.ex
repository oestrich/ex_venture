defmodule Data.Config do
  @moduledoc """
  Config Schema
  """

  use Data.Schema

  schema "config" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :value])
    |> validate_required([:name, :value])
  end

  def find_config(name) do
    __MODULE__
    |> where([c], c.name == ^name)
    |> select([c], c.value)
    |> Repo.one
  end
end
