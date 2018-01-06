defmodule Data.Repo.Migrations.AddNameToNpcSpawners do
  use Ecto.Migration

  def change do
    alter table(:npc_spawners) do
      add :name, :string
    end
  end
end
