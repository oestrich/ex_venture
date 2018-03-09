defmodule Data.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false

      timestamps()
    end
  end
end
