defmodule Data.Repo.Migrations.AddMapLayerToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :map_layer, :integer, default: 1, null: false
    end

    create index(:rooms, [:zone_id, :x, :y, :map_layer], unique: true)
    drop index(:rooms, [:zone_id, :x, :y])
  end
end
