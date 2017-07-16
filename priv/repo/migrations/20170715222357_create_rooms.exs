defmodule Data.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :string, null: false

      add :north_id, references(:rooms)
      add :east_id, references(:rooms)
      add :south_id, references(:rooms)
      add :west_id, references(:rooms)

      timestamps()
    end
  end
end
