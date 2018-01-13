defmodule Data.Repo.Migrations.AddConversationTreeToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :conversations, {:array, :jsonb}
    end
  end
end
