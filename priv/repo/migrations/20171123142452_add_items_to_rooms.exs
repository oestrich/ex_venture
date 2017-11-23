defmodule Data.Repo.Migrations.AddItemsToRooms do
  use Ecto.Migration

  def up do
    alter table(:rooms) do
      add :items, {:array, :jsonb}, default: fragment("'{}'"), null: false
      remove :item_ids
    end
  end

  def down do
    alter table(:rooms) do
      add :item_ids, {:array, :integer}, default: fragment("'{}'"), null: false
      remove :items
    end
  end
end
