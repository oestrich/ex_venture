defmodule Data.Repo.Migrations.CreateItemTaggings do
  use Ecto.Migration

  def change do
    create table(:item_taggings) do
      add :item_id, references(:items), null: false
      add :item_tag_id, references(:item_tags), null: false

      timestamps()
    end

    create index(:item_taggings, [:item_id, :item_tag_id], unique: true)
  end
end
