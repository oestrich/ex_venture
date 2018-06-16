defmodule Data.Repo.Migrations.AddOverworldIdsToExits do
  use Ecto.Migration

  def up do
    alter table(:exits) do
      add :start_overworld_id, :string
      add :start_zone_id, references(:zones)

      add :finish_overworld_id, :string
      add :finish_zone_id, references(:zones)

      modify :start_id, :integer, null: true
      modify :finish_id, :integer, null: true
    end

    rename table(:exits), :start_id, to: :start_room_id
    rename table(:exits), :finish_id, to: :finish_room_id
  end

  def down do
    rename table(:exits), :start_room_id, to: :start_id
    rename table(:exits), :finish_room_id, to: :finish_id

    alter table(:exits) do
      remove :start_overworld_id
      remove :start_zone_id

      remove :finish_overworld_id
      remove :finish_zone_id

      modify :start_id, :integer, null: false
      modify :finish_id, :integer, null: false
    end
  end
end
