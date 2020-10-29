defmodule ExVenture.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string, null: false)
      add(:first_name, :string, null: false)
      add(:last_name, :string, null: false)
      add(:password_hash, :string, null: false)
      add(:token, :uuid, null: false)

      add(:email_verification_token, :uuid)
      add(:email_verified_at, :utc_datetime)

      add(:password_reset_token, :uuid)
      add(:password_reset_expires_at, :utc_datetime)

      add(:avatar_key, :uuid)
      add(:avatar_extension, :string)

      timestamps()
    end

    create index(:users, ["lower(email)"], unique: true)
  end
end
