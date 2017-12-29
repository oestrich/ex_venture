defmodule Data.Repo.Migrations.CreateMail do
  use Ecto.Migration

  def change do
    create table(:mail) do
      add :sender_id, references(:users), null: false
      add :receiver_id, references(:users), null: false
      add :title, :string, null: false
      add :body, :string
      add :is_read, :boolean, default: false, null: false

      timestamps()
    end
  end
end
