defmodule Data.Repo.Migrations.AddUpDownToRoomExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      add :up_id, references(:rooms)
      add :down_id, references(:rooms)
    end

    create index(:exits, :up_id, unique: true)
    create index(:exits, :down_id, unique: true)
  end
end
