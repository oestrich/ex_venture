defmodule Data.Repo.Migrations.AddOverworldMapToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :overworld_map, {:array, :jsonb}
    end
  end
end
