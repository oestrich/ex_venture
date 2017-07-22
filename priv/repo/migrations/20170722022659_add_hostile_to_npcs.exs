defmodule Data.Repo.Migrations.AddHostileToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :hostile, :boolean, default: false, null: false
    end
  end
end
