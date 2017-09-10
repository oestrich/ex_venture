defmodule Data.Repo.Migrations.CreateRaces do
  use Ecto.Migration

  def change do
    create table(:races) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :starting_stats, :map, null: false

      timestamps()
    end

    alter table(:classes) do
      remove :starting_stats
      add :each_level_stats, :map, null: false
    end

    alter table(:users) do
      add :race_id, references(:races), null: false
    end
  end
end
