defmodule Data.Class do
  @moduledoc """
  Class schema
  """

  use Data.Schema

  alias Data.ClassAbility
  alias Data.ClassSkill

  schema "classes" do
    field(:api_id, Ecto.UUID, read_after_writes: true)
    field(:name, :string)
    field(:description, :string)

    has_many(:class_abilities, ClassAbility)
    has_many(:class_skills, ClassSkill)
    has_many(:skills, through: [:class_skills, :skill])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
