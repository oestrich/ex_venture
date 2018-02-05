defmodule Data.Repo.Migrations.AddSkillsToRaces do
  use Ecto.Migration

  def change do
    create table(:race_skills) do
      add :race_id, references(:races), null: false
      add :skill_id, references(:skills), null: false

      timestamps()
    end

    create index(:race_skills, [:race_id, :skill_id], unique: true)
  end
end
