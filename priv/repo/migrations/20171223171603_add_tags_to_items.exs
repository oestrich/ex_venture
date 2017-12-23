defmodule Data.Repo.Migrations.AddTagsToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :tags, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
