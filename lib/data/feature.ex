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

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:key, :short_description, :description, :listen])
    |> validate_required([:key, :short_description, :description])
  end
end
