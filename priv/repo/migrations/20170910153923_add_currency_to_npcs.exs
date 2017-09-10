defmodule Data.Repo.Migrations.AddCurrencyToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :currency, :integer, default: 0, null: false
    end
  end
end
