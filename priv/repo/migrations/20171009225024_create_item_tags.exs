defmodule Data.Repo.Migrations.CreateItemModules do
  use Ecto.Migration

  def change do
    create table(:item_tags) do
      add :name, :string, null: false
      add :description, :string, null: false
      add :type, :string, null: false
      add :stats, :map, default: fragment("'{}'"), null: false
      add :effects, {:array, :map}, default: fragment(~s('{}')), null: false

      timestamps()
    end
  end
end
