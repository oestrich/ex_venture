defmodule Data.Repo.Migrations.CreateNpcs do
  use Ecto.Migration

  def change do
    create table(:npcs) do
      add :name, :string, null: false
      add :room_id, references(:rooms), null: false

      timestamps()
    end
  end
end
