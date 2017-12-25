defmodule Data.Repo.Migrations.RemoveHostileFromNpcs do
  use Ecto.Migration

  def up do
    alter table(:npcs) do
      remove :hostile
    end
  end

  def down do
    alter table(:npcs) do
      add :hostile, :boolean, default: false, null: false
    end
  end
end
