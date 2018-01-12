defmodule Data.Note do
  @moduledoc """
  Class schema
  """

  use Data.Schema

  schema "notes" do
    field :name, :string
    field :body, :string
    field :tags, {:array, :string}, default: []

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :body, :tags])
    |> validate_required([:name, :body, :tags])
  end
end
