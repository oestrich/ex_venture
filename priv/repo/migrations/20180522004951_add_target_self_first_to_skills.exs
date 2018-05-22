defmodule Data.Repo.Migrations.AddTargetSelfFirstToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :require_target, :boolean, default: false, null: false
    end
  end
end
