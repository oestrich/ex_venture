defmodule Data.Repo.Migrations.AddExamineToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :description, :string, default: "{status_line}", null: false
    end
  end
end
