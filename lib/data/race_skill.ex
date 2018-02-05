defmodule Data.RaceSkill do
  @moduledoc """
  Race Skill schema
  """

  use Data.Schema

  alias Data.Race
  alias Data.Skill

  schema "race_skills" do
    belongs_to(:race, Race)
    belongs_to(:skill, Skill)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:race_id, :skill_id])
    |> validate_required([:race_id, :skill_id])
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:skill_id)
    |> unique_constraint(:race_id, name: :race_skills_race_id_skill_id_index)
  end
end
