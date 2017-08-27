defmodule Data.Repo.Migrations.AddRegenToClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :regen_health, :integer, null: false
      add :regen_skill_points, :integer, null: false
    end
  end
end
