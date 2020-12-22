defmodule ExVenture.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add(:token, :uuid, null: false)
      add(:is_active, :boolean, default: true, null: false)

      timestamps()
    end

    create index(:api_keys, :token, unique: true)
  end
end
