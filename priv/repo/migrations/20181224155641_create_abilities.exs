defmodule Data.Repo.Migrations.CreateAbilities do
  use Ecto.Migration

  def change do
    create table(:proficiencies) do
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:description, :string)

      timestamps()
    end

    create table(:class_proficiencies) do
      add(:class_id, references(:classes), null: false)
      add(:proficiency_id, references(:proficiencies), null: false)
      add(:level, :integer, null: false)
      add(:ranks, :integer, null: false)

      timestamps()
    end

    create index(:class_proficiencies, [:class_id, :proficiency_id], unique: true)
  end
end
