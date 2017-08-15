defmodule Data.Repo.Migrations.CreateSkills do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :class_id, references(:classes), null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :user_text, :text, null: false
      add :usee_text, :text, null: false
      add :command, :string, null: false
      add :effects, {:array, :map}, default: fragment("'{}'"), null: false
    end
  end
end
