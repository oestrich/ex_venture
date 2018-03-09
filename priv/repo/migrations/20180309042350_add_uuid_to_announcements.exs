defmodule Data.Repo.Migrations.AddUuidToAnnouncements do
  use Ecto.Migration

  def up do
    execute "create extension \"uuid-ossp\";"

    alter table(:announcements) do
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    create index(:announcements, :uuid)
  end

  def down do
    drop index(:announcements, :uuid)

    alter table(:announcements) do
      remove :uuid
    end

    execute "drop extension \"uuid-ossp\";"
  end
end
