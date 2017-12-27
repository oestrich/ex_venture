defmodule Data.Repo.Migrations.AddLevelsToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :starting_level, :integer, default: 1
      add :ending_level, :integer, default: 1
    end
  end
end
