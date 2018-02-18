defmodule Data.Repo.Migrations.AddRoomIdToQuestSteps do
  use Ecto.Migration

  def change do
    alter table(:quest_steps) do
      add :room_id, references(:rooms)
    end

    create index(:quest_steps, [:quest_id, :room_id], unique: true)
  end
end
