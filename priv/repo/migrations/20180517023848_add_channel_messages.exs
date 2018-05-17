defmodule Data.Repo.Migrations.AddChannelMessages do
  use Ecto.Migration

  def change do
    create table(:channel_messages) do
      add :channel_id, references(:channels), null: false
      add :user_id, references(:users), null: false
      add :message, :string, null: false
      add :formatted, :string, null: false

      timestamps()
    end
  end
end
