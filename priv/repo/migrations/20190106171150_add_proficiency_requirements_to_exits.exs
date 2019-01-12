defmodule Data.Repo.Migrations.AddProficiencyRequirementsToExits do
  use Ecto.Migration

  def change do
    alter table(:exits) do
      add(:requirements, {:array, :jsonb}, default: fragment("'{}'"), null: false)
    end
  end
end
