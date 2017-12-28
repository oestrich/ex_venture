defmodule Data.Repo.Migrations.CreateTypos do
  use Ecto.Migration

  def change do
    create table(:typos) do
      add :title, :string, null: false
      add :body, :text
      add :reporter_id, references(:users), null: false
      add :room_id, references(:rooms), null: false

      timestamps()
    end
  end
end
