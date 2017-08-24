defmodule Data.Repo.Migrations.AddNpcSpawnTime do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :spawn_interval, :integer, default: 30, null: false
    end

    rename table(:room_items), :interval, to: :spawn_interval
  end
end
