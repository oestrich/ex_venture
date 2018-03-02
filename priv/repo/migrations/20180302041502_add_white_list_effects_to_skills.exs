defmodule Data.Repo.Migrations.AddWhiteListEffectsToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :white_list_effects, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
