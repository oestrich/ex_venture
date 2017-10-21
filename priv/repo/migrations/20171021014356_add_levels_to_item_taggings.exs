defmodule Data.Repo.Migrations.AddLevelsToItemTaggings do
  use Ecto.Migration

  def change do
    alter table(:item_taggings) do
      add :level, :integer, default: 1, null: false
    end
  end
end
