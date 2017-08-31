defmodule Data.Repo.Migrations.AddCoordinatesToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :x, :integer, null: false
      add :y, :integer, null: false
    end

    create index(:rooms, [:zone_id, :x, :y], unique: true)
  end
end
