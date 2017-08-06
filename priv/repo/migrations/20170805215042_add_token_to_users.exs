defmodule Data.Repo.Migrations.AddTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :token, :uuid, null: false
    end

    create index(:users, :token, unique: true)
  end
end
