defmodule Data.DamageType do
  @moduledoc """
  Damage Type schema
  """

  use Data.Schema

  alias Data.Stats

  schema "damage_types" do
    field(:key, :string)
    field(:stat_modifier, Stats.Type)
    field(:boost_ratio, :integer, default: 20)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:key, :stat_modifier, :boost_ratio])
    |> validate_required([:key, :stat_modifier, :boost_ratio])
    |> validate_inclusion(:stat_modifier, Stats.basic_fields())
    |> validate_number(:boost_ratio, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:key)
  end
end
