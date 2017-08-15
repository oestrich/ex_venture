defmodule Data.Repo.Migrations.AddStatsToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :stats, :map, default: fragment("'{}'"), null: false
    end
  end
end
