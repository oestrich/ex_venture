defmodule Data.Repo.Migrations.AddDisabledToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :is_enabled, :boolean, default: true, null: false
    end
  end
end
