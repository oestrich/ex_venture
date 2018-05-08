defmodule Data.Repo.Migrations.AddPasswordResetFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_reset_token, :uuid
      add :password_reset_expires_at, :utc_datetime
    end
  end
end
