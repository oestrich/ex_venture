defmodule Data.Repo.Migrations.AddZoneExitToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :is_zone_exit, :boolean, default: false, null: false
    end
  end
end
