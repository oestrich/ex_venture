defmodule Data.Repo.Migrations.DropItemIdsFromNpcs do
  use Ecto.Migration

  def up do
    alter table(:npcs) do
      remove :item_ids
    end

    alter table(:items) do
      remove :drop_rate
    end
  end

  def down do
    alter table(:npcs) do
      add :item_ids, {:array, :integer}, default: fragment("'{}'"), null: false
    end

    alter table(:items) do
      add :drop_rate, :integer, default: 10, null: false
    end
  end
end
