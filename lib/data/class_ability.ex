defmodule Data.ClassAbility do
  @moduledoc """
  Class Ability schema
  """

  use Data.Schema

  alias Data.Class
  alias Data.Ability

  schema "class_abilities" do
    field(:level, :integer)
    field(:points, :integer)

    belongs_to(:class, Class)
    belongs_to(:ability, Ability)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:class_id, :ability_id, :level, :points])
    |> validate_required([:class_id, :ability_id, :level, :points])
    |> validate_number(:level, greater_than: 0)
    |> validate_number(:points, greater_than: 0)
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:ability_id)
    |> unique_constraint(:class_id, name: :class_abilities_class_id_ability_id_index)
  end
end
