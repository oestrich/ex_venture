defmodule Data.Repo.Migrations.AddInOutIdsToExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      add :in_id, references(:rooms)
      add :out_id, references(:rooms)
    end

    create index(:exits, :in_id, unique: true)
    create index(:exits, :out_id, unique: true)
  end
end
