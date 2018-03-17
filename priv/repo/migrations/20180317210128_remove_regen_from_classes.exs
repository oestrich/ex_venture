defmodule Data.Repo.Migrations.RemoveRegenFromClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      remove :regen_health_points
      remove :regen_skill_points
    end
  end
end
