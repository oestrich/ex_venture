defmodule Data.Repo.Migrations.CreateClasses do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :starting_stats, :map, null: false
    end

    alter table(:users) do
      add :class_id, references(:classes), null: false
    end
  end
end
