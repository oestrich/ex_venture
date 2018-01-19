defmodule Data.Repo.Migrations.AddIsQuestGiverToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :is_quest_giver, :boolean, default: false, null: false
    end

    alter table(:quests) do
      add :conversations, {:array, :jsonb}, null: false
    end
  end
end
