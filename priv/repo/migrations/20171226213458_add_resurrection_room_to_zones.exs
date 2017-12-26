defmodule Data.Repo.Migrations.AddResurrectionRoomToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :graveyard_id, references(:rooms)
    end

    alter table(:rooms) do
      add :is_graveyard, :boolean, default: false, null: false
    end
  end
end
