defmodule Data.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :name, :string, null: false
      add :body, :text, null: false
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false

      timestamps()
    end
  end
end
