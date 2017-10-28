defmodule Data.Repo.Migrations.AddEventsToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :events, {:array, :jsonb}, default: fragment("'{}'"), null: false
    end
  end
end
