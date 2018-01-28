defmodule Data.Repo.Migrations.AddUniqueIndexToClassSkills do
  use Ecto.Migration

  def change do
    create index(:class_skills, [:class_id, :skill_id], unique: true)
  end
end
