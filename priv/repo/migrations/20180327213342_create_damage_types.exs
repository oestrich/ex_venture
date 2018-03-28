defmodule Data.Repo.Migrations.CreateDamageTypes do
  use Ecto.Migration

  def change do
    create table(:damage_types) do
      add :key, :string, null: false
      add :stat_modifier, :string, null: false
      add :percentage_boost, :integer, null: false

      timestamps()
    end

    create index(:damage_types, :key, unique: true)
  end
end
