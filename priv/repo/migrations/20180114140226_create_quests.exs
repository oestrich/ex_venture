defmodule Data.Repo.Migrations.CreateQuests do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :giver_id, references(:npcs), null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :level, :integer, null: false
      add :experience, :integer, null: false

      timestamps()
    end

    create table(:quest_steps) do
      add :quest_id, references(:quests), null: false
      add :type, :string, null: false
      add :item_id, references(:items)
      add :npc_id, references(:npcs)
      add :count, :integer

      timestamps()
    end

    create table(:quest_relations) do
      add :parent_id, references(:quests), null: false
      add :child_id, references(:quests), null: false

      timestamps()
    end

    create index(:quest_relations, [:parent_id, :child_id], unique: true)

    create table(:player_quests) do
      add :quest_id, references(:quests), null: false
      add :user_id, references(:users), null: false
      add :status, :string, null: false
      add :progress, :jsonb, default: fragment("'{}'"), null: false

      timestamps()
    end
  end
end
