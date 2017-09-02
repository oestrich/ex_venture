defmodule Data.Repo.Migrations.CreateExits do
  use Ecto.Migration

  def change do
    create table(:exits) do
      add :north_id, references(:rooms)
      add :south_id, references(:rooms)
      add :west_id, references(:rooms)
      add :east_id, references(:rooms)

      timestamps()
    end

    create index(:exits, :north_id, unique: true)
    create index(:exits, :south_id, unique: true)
    create index(:exits, :west_id, unique: true)
    create index(:exits, :east_id, unique: true)

    alter table(:rooms) do
      remove :north_id
      remove :east_id
      remove :south_id
      remove :west_id
    end
  end
end
