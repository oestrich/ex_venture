defmodule Data.Repo.Migrations.AddTagsToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
