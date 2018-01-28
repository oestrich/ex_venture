defmodule Data.Repo.Migrations.CreateClassSkills do
  use Ecto.Migration

  def up do
    create table(:class_skills) do
      add :class_id, references(:classes), null: false
      add :skill_id, references(:skills), null: false

      timestamps()
    end

    execute "insert into class_skills (class_id, skill_id, inserted_at, updated_at) select class_id, id as skill_id, now(), now() from skills;"

    alter table(:skills) do
      remove :class_id
    end
  end

  def down do
    raise "No going back now..."
  end
end
