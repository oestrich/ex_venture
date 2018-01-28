defmodule Data.ClassSkill do
  @moduledoc """
  Class Skill schema
  """

  use Data.Schema

  alias Data.Class
  alias Data.Skill

  schema "class_skills" do
    belongs_to(:class, Class)
    belongs_to(:skill, Skill)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:class_id, :skill_id])
    |> validate_required([:class_id, :skill_id])
    |> foreign_key_constraint(:class_id)
    |> foreign_key_constraint(:skill_id)
    |> unique_constraint(:class_id, name: :class_skills_class_id_skill_id_index)
  end
end
