defmodule Data.Repo.Migrations.AddCostToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :cost, :integer, default: 0, null: false
    end
  end
end
