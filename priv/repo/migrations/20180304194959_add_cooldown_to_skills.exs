defmodule Data.Repo.Migrations.AddCooldownToSkills do
  use Ecto.Migration

  def change do
    alter table(:skills) do
      add :cooldown_time, :integer, default: 3000, null: false
    end
  end
end
