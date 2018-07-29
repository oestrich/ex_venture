defmodule Data.Repo.Migrations.AddFeatureIdsToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :feature_ids, {:array, :integer}, default: fragment("'{}'"), null: false
    end
  end
end
