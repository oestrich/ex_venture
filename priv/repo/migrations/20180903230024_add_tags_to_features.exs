defmodule Data.Repo.Migrations.AddTagsToFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
