defmodule Data.Skill do
  @moduledoc """
  Skill schema
  """

  use Data.Schema

  import Data.Effect, only: [validate_effects: 1]

  alias Data.ClassSkill
  alias Data.Effect

  schema "skills" do
    field(:api_id, Ecto.UUID, read_after_writes: true)
    field(:name, :string)
    field(:description, :string)
    field(:level, :integer)
    field(:points, :integer)
    field(:user_text, :string)
    field(:usee_text, :string)
    field(:command, :string)
    field(:cooldown_time, :integer, default: 3000)
    field(:whitelist_effects, {:array, :string}, default: [])
    field(:effects, {:array, Effect}, default: [])
    field(:tags, {:array, :string}, default: [])
    field(:is_enabled, :boolean, default: true)
    field(:is_global, :boolean, default: false)
    field(:require_target, :boolean, default: false)

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
      :cooldown_time,
      :whitelist_effects,
      :effects,
      :tags,
      :is_enabled,
      :is_global,
      :require_target
    ])
    |> validate_required([
      :name,
      :description,
      :level,
      :points,
      :user_text,
      :usee_text,
      :command,
      :cooldown_time,
      :whitelist_effects,
      :effects,
      :tags,
      :is_enabled,
      :is_global,
      :require_target
    ])
    |> validate_effects()
    |> validate_whitelist()
    |> validate_number(:cooldown_time, greater_than_or_equal_to: 0)
  end

  defp validate_whitelist(changeset) do
    case get_field(changeset, :whitelist_effects) do
      nil ->
        changeset

      whitelist_effects ->
        _validate_whitelist(changeset, whitelist_effects)
    end
  end

  defp _validate_whitelist(changeset, whitelist_effects) do
    case Enum.all?(whitelist_effects, &(&1 in Effect.types())) do
      true ->
        changeset

      false ->
        add_error(changeset, :whitelist_effects, "must all be a real type")
    end
  end
end
