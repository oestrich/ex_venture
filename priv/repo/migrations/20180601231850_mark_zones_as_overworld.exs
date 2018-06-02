defmodule Data.Repo.Migrations.MarkZonesAsOverworld do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :type, :string, default: "rooms", null: false
    end
  end
end
