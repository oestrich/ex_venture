defmodule ExVenture.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add(:name, :string, null: false)

      timestamps()
    end

    create table(:playable_characters) do
      add(:character_id, references(:characters), null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end
  end
end
