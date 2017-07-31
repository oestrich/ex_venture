defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  schema "zones" do
    field :name, :string

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
