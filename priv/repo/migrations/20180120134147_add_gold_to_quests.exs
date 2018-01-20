defmodule Data.Repo.Migrations.AddGoldToQuests do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :currency, :integer, default: 0, null: false
    end
  end
end
