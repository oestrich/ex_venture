defmodule Data.Repo.Migrations.AddSaveToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :save, :map, default: fragment("'{}'"), null: false
    end

    execute "update users set save = (select to_jsonb(t) from (select id as room_id from rooms limit 1) t);"
  end

  def down do
    alter table(:users) do
      remove :save
    end
  end
end
