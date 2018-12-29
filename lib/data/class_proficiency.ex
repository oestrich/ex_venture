defmodule Data.ClassProficiency do
  @moduledoc """
  Class Proficiency schema
  """

  use Data.Schema

  alias Data.Class
  alias Data.Proficiency

  schema "class_proficiencies" do
    field(:level, :integer)
    field(:points, :integer)

    belongs_to(:class, Class)
    belongs_to(:proficiency, Proficiency)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:class_id, :proficiency_id, :level, :points])
    |> validate_required([:class_id, :proficiency_id, :level, :points])
    |> validate_number(:level, greater_than: 0)
    |> validate_number(:points, greater_than: 0)
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:proficiency_id)
    |> unique_constraint(:class_id, name: :class_proficiencies_class_id_proficiency_id_index)
  end
end
