defmodule Data.Repo.Migrations.CreateFeatures do
  use Ecto.Migration

  def change do
    create table(:features) do
      add :key, :string, null: false
      add :short_description, :text, null: false
      add :description, :text, null: false
      add :listen, :text

      timestamps()
    end
  end
end
