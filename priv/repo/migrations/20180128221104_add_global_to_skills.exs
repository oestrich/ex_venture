defmodule Data.Repo.Migrations.AddGlobalToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :is_global, :boolean, default: false, null: false
    end
  end
end
