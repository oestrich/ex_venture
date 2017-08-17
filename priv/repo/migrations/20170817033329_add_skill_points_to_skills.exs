defmodule Data.Repo.Migrations.AddSkillPointsToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :points, :integer, default: 1, null: false
    end
  end
end
