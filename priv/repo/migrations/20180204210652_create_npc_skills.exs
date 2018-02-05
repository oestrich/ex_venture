defmodule Data.Repo.Migrations.CreateNpcSkills do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :is_trainer, :boolean, default: false, null: false
      add :trainable_skills, {:array, :integer}, default: fragment("'{}'"), null: false
    end
  end
end
