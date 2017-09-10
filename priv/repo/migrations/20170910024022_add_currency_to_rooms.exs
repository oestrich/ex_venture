defmodule Data.Repo.Migrations.AddCurrencyToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :currency, :integer, default: 0, null: false
    end
  end
end
