defmodule Data.Repo.Migrations.ChangeDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      modify :description, :text, null: false
    end
  end
end
