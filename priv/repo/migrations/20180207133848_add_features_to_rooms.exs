defmodule Data.Repo.Migrations.AddFeaturesToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :features, {:array, :jsonb}, default: fragment("'{}'"), null: false
    end
  end
end
