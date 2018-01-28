defmodule Data.Repo.Migrations.AddTagsToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
