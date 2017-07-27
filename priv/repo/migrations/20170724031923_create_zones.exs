defmodule Data.Repo.Migrations.CreateZones do
  use Ecto.Migration

  def change do
    create table(:zones) do
      add :name, :string, null: false

      timestamps()
    end

    alter table(:rooms) do
      add :zone_id, references(:zones), null: false
    end
  end
end
