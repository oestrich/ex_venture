defmodule Data.Repo.Migrations.AddTotpSecretToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :totp_secret, :string
      add :totp_verified_at, :utc_datetime
    end
  end
end
