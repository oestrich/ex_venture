defmodule Data.Repo.Migrations.AddTypeToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :type, :string, default: "basic", null: false
    end
  end
end
