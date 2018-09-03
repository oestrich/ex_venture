defmodule Data.Feature do
  @moduledoc """
  Feature schema
  """

  use Data.Schema

  schema "features" do
    field(:key, :string)
    field(:short_description, :string)
    field(:description, :string)
    field(:listen, :string)
    field(:tags, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:key, :short_description, :description, :listen, :tags])
    |> validate_required([:key, :short_description, :description, :tags])
  end
end
