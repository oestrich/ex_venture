defmodule Data.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :keywords, {:array, :string}, null: false

      timestamps()
    end

    create table(:room_items) do
      add :room_id, references(:rooms)
      add :item_id, references(:items)
      add :spawn, :boolean, default: false, null: false
      add :interval, :integer

      timestamps()
    end

    alter table(:rooms) do
      add :item_ids, {:array, :integer}, default: fragment("'{}'"), null: false
    end

    create index(:room_items, :room_id)
    create index(:room_items, [:room_id, :item_id], unique: true)
  end
end
