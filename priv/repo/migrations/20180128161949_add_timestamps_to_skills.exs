defmodule Data.Repo.Migrations.AddTimestampsToSkills do
  use Ecto.Migration

  def up do
    alter table(:skills) do
      add :inserted_at, :utc_datetime
      add :updated_at, :utc_datetime
    end

    execute "update skills set inserted_at = now(), updated_at = now()"

    alter table(:skills) do
      modify :inserted_at, :utc_datetime, null: false
      modify :updated_at, :utc_datetime, null: false
    end
  end

  def down do
    alter table(:skills) do
      remove :inserted_at
      remove :updated_at
    end
  end
end
