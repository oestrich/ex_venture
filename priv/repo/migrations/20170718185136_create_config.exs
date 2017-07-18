defmodule Data.Repo.Migrations.CreateConfig do
  use Ecto.Migration

  def change do
    create table(:config) do
      add :name, :string, null: false
      add :value, :text, null: false

      timestamps()
    end
  end
end
