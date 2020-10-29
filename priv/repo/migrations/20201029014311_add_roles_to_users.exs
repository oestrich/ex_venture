defmodule ExVenture.Repo.Migrations.AddRolesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:role, :string, default: "player", null: false)
    end
  end
end
