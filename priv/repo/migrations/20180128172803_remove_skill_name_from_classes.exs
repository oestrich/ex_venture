defmodule Data.Repo.Migrations.RemoveSkillNameFromClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      remove :points_name
      remove :points_abbreviation
    end
  end
end
