defmodule Data.Repo.Migrations.AddCodeToSkills do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :module_name, :string, null: false
    end

    create index(:classes, :module_name, unique: true)

    alter table(:skills) do
      add :module_name, :string, null: false
      add :code, :text, null: false
    end

    create index(:skills, [:class_id, :module_name], unique: true)
  end
end
