defmodule Data.Repo.Migrations.DropSpawnFromRoomItems do
  use Ecto.Migration

  def change do
    alter table(:room_items) do
      remove :spawn
    end
  end
end
