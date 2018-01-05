defmodule Data.Repo.Migrations.AddUseCountToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :is_usable, :boolean, default: false, null: false
      add :amount, :integer, default: 1, null: false
    end
  end
end
