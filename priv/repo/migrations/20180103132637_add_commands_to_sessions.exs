defmodule Data.Repo.Migrations.AddCommandsToSessions do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :commands, :jsonb, default: fragment("'{}'"), null: false
    end
  end
end
