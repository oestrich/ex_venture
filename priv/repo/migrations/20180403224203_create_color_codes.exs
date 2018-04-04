defmodule Data.Repo.Migrations.CreateColorCodes do
  use Ecto.Migration

  def change do
    create table(:color_codes) do
      add :key, :string, null: false
      add :ansi_escape, :string, null: false
      add :hex_code, :string, null: false

      timestamps()
    end

    create index(:color_codes, :key, unqiue: true)
  end
end
