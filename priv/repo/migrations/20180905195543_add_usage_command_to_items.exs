defmodule Data.Repo.Migrations.AddUsageCommandToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :usage_command, :string
    end
  end
end
