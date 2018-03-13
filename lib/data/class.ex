defmodule Data.Class do
  @moduledoc """
  Class schema
  """

  use Data.Schema

  alias Data.ClassSkill
  alias Data.Stats

  schema "classes" do
    field(:name, :string)
    field(:description, :string)

    field(:regen_health_points, :integer)
    field(:regen_skill_points, :integer)

    has_many(:class_skills, ClassSkill)
    has_many(:skills, through: [:class_skills, :skill])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :description,
      :regen_health_points,
      :regen_skill_points
    ])
    |> validate_required([
      :name,
      :description,
      :regen_health_points,
      :regen_skill_points
    ])
  end
end
