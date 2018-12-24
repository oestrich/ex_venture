defmodule Data.Repo.Migrations.CreateAbilities do
  use Ecto.Migration

  def change do
    create table(:abilities) do
      add(:name, :string, null: false)
      add(:type, :string, null: false)

      timestamps()
    end
  end
end
