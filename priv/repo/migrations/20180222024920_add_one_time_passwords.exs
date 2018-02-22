defmodule Data.Repo.Migrations.AddOneTimePasswords do
  use Ecto.Migration

  def change do
    create table(:one_time_passwords) do
      add :user_id, references(:users), null: false
      add :password, :uuid, null: false
      add :used_at, :utc_datetime

      timestamps()
    end
  end
end
