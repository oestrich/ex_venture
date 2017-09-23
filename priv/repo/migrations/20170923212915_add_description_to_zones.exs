defmodule Data.Repo.Migrations.AddDescriptionToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :description, :string, default: "", null: false
    end
  end
end
