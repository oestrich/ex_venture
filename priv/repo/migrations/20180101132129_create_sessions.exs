defmodule Data.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :user_id, references(:users), null: false
      add :started_at, :utc_datetime, null: false
      add :seconds_online, :integer, null: false

      timestamps()
    end
  end
end
