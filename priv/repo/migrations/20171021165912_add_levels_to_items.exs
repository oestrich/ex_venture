defmodule Data.Repo.Migrations.AddLevelsToItems do
  use Ecto.Migration

  def change do
    alter table(:item_taggings) do
      remove :level
    end

    alter table(:items) do
      add :level, :integer, default: 1, null: false
    end
  end
end
