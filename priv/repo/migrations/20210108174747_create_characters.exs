defmodule ExVenture.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add(:user_id, references(:users), null: false)
      add(:name, :string, null: false)

      timestamps()
    end
  end
end
