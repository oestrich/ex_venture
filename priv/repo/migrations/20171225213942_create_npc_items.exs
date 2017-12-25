defmodule Data.Repo.Migrations.CreateNpcItems do
  use Ecto.Migration

  def change do
    create table(:npc_items) do
      add :item_id, references(:items), null: false
      add :npc_id, references(:npcs), null: false
      add :drop_rate, :integer, default: 10, null: false

      timestamps()
    end
  end
end
