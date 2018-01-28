defmodule Data.Skill do
  @moduledoc """
  Skill schema
  """

  use Data.Schema

  import Data.Effect, only: [validate_effects: 1]

  alias Data.ClassSkill
  alias Data.Effect

  schema "skills" do
    field(:name, :string)
    field(:description, :string)
    field(:level, :integer)
    field(:points, :integer)
    field(:user_text, :string)
    field(:usee_text, :string)
    field(:command, :string)
    field(:effects, {:array, Effect})
    field(:tags, {:array, :string}, default: [])
    field(:is_global, :boolean, default: false)

    has_many(:class_skills, ClassSkill)
    has_many(:classes, through: [:class_skills, :class])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :description,
      :level,
      :points,
      :user_text,
      :usee_text,
      :command,
      :effects,
      :tags,
      :is_global
    ])
    |> validate_required([
      :name,
      :description,
      :level,
      :points,
      :user_text,
      :usee_text,
      :command,
      :effects,
      :tags,
      :is_global
    ])
    |> validate_effects()
  end
end
