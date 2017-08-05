defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  schema "zones" do
    field :name, :string

    has_many :rooms, Data.Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
