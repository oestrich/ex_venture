defmodule Data.Repo.Migrations.AddLevelToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :level, :integer, default: 1, null: false
    end
  end
end
