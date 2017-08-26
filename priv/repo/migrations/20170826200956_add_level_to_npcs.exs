defmodule Data.Repo.Migrations.AddLevelToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :level, :integer, null: false
      add :experience_points, :integer, null: false
    end
  end
end
