defmodule Data.Repo.Migrations.CreateAbilities do
  use Ecto.Migration

  def change do
    create table(:abilities) do
      add(:name, :string, null: false)
      add(:type, :string, null: false)

      timestamps()
    end

    create table(:class_abilities) do
      add(:class_id, references(:classes), null: false)
      add(:ability_id, references(:abilities), null: false)
      add(:level, :integer, null: false)
      add(:points, :integer, null: false)

      timestamps()
    end

    create index(:class_abilities, [:class_id, :ability_id], unique: true)
  end
end
