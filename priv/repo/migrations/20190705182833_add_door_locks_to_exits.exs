defmodule Data.Repo.Migrations.AddDoorLocksToExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      add(:has_lock, :boolean, default: false, null: false)
      add :lock_key_id, references(:items)
    end
  end
end
