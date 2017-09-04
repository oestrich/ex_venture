defmodule Data.Repo.Migrations.RenameZoneNpcsToNpcSpawners do
  use Ecto.Migration

  def change do
    rename table(:zone_npcs), to: table(:npc_spawners)
  end
end
