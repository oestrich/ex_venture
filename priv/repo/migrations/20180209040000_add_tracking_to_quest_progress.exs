defmodule Data.Repo.Migrations.AddTrackingToQuestProgress do
  use Ecto.Migration

  def change do
    alter table(:quest_progress) do
      add :is_tracking, :boolean, default: false, null: false
    end
  end
end
