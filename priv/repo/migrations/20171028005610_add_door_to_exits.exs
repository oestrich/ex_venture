defmodule Data.Repo.Migrations.AddDoorToExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      add :has_door, :boolean, default: false, null: false
    end
  end
end
