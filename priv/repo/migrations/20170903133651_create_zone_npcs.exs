defmodule Data.Repo.Migrations.CreateZoneNpcs do
  use Ecto.Migration

  def change do
    create table(:zone_npcs) do
      add :npc_id, references(:npcs)
      add :zone_id, references(:zones)
      add :room_id, references(:rooms)
      add :spawn_interval, :integer, null: false

      timestamps()
    end

    alter table(:npcs) do
      remove :room_id
      remove :spawn_interval
    end
  end
end
