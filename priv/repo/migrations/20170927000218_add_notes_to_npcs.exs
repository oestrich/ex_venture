defmodule Data.Repo.Migrations.AddNotesToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :notes, :text
    end
  end
end
