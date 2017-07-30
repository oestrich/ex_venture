defmodule Data.Repo.Migrations.AddStatsToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :stats, :map, default: fragment("'{}'"), null: false
    end
  end
end
