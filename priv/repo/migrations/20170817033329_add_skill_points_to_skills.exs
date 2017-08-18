defmodule Data.Repo.Migrations.AddSkillPointsToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :points, :integer, default: 1, null: false
    end
    alter table(:classes) do
      add :points_name, :string, null: false
      add :points_abbreviation, :string, null: false
    end
  end
end
