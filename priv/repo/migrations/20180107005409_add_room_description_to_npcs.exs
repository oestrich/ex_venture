defmodule Data.Repo.Migrations.AddRoomDescriptionToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :status_line, :string, default: "{name} is here.", null: false
    end
  end
end
