defmodule Data.Repo.Migrations.ReworkUniqueIndexesOnExits do
  use Ecto.Migration

  def up do
    drop index(:exits, [:direction, :start_room_id, :finish_room_id], name: :exits_direction_start_id_finish_id_index)

    create index(:exits, [:direction, :start_room_id], unique: true)
    create index(:exits, [:direction, :start_overworld_id], unique: true)
    create index(:exits, [:direction, :finish_room_id], unique: true)
    create index(:exits, [:direction, :finish_overworld_id], unique: true)
  end
end
