defmodule Data.Repo.Migrations.CreateShops do
  use Ecto.Migration

  def change do
    create table(:shops) do
      add :room_id, references(:rooms), null: false
      add :name, :string, null: false

      timestamps()
    end

    create table(:shop_items) do
      add :shop_id, references(:shops), null: false
      add :item_id, references(:items), null: false
      add :price, :integer, null: false

      timestamps()
    end
  end
end
