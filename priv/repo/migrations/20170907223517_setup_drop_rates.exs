defmodule Data.Repo.Migrations.SetupDropRates do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :drop_rate, :integer, default: 100, null: false
    end

    alter table(:npcs) do
      add :item_ids, {:array, :integer}, default: fragment("'{}'"), null: false
    end
  end
end
