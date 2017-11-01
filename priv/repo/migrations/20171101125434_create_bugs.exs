defmodule Data.Repo.Migrations.CreateBugs do
  use Ecto.Migration

  def change do
    create table(:bugs) do
      add :title, :string, null: false
      add :body, :text
      add :reporter_id, references(:users), null: false

      timestamps()
    end
  end
end
