defmodule Data.Repo.Migrations.AddProviderInformationToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify(:name, :string, null: true)
      modify(:password_hash, :string, null: true)
      add(:provider, :text)
      add(:provider_uid, :text)
    end

    create index(:users, [:provider, :provider_uid], unique: true)
  end

  def down do
    drop index(:users, [:provider, :provider_uid])

    alter table(:users) do
      modify(:name, :string, null: false)
      modify(:password_hash, :string, null: false)
      remove(:provider)
      remove(:provider_uid)
    end
  end
end
