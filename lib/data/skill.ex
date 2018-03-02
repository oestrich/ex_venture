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
    field(:white_list_effects, {:array, :string}, default: [])
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
      :white_list_effects,
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
      :white_list_effects,
      :effects,
      :tags,
      :is_global
    ])
    |> validate_effects()
    |> validate_white_list()
  end

  defp validate_white_list(changeset) do
    case get_field(changeset, :white_list_effects) do
      nil ->
        changeset

      white_list_effects ->
        _validate_white_list(changeset, white_list_effects)
    end
  end

  defp _validate_white_list(changeset, white_list_effects) do
    case Enum.all?(white_list_effects, & &1 in Effect.types()) do
      true ->
        changeset

      false ->
        add_error(changeset, :white_list_effects, "must all be a real type")
    end
  end
end
