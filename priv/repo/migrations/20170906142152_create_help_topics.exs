defmodule Data.Repo.Migrations.CreateHelpTopics do
  use Ecto.Migration

  def change do
    create table(:help_topics) do
      add :name, :string, null: false
      add :keywords, {:array, :string}, default: fragment("'{}'"), null: false
      add :body, :text, null: false

      timestamps()
    end
  end
end
