defmodule Data.Repo.Migrations.AddCompleteToBugs do
  use Ecto.Migration

  def change do
    alter table(:bugs) do
      add :is_completed, :boolean, default: false, null: false
    end
  end
end
