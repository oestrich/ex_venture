defmodule Data.Repo.Migrations.RenameConversationsToScripts do
  use Ecto.Migration

  def change do
    rename table(:npcs), :conversations, to: :script
    rename table(:quests), :conversations, to: :script
  end
end
