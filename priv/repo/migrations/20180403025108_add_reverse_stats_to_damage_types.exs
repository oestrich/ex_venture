defmodule Data.Repo.Migrations.AddReverseStatsToDamageTypes do
  use Ecto.Migration

  def up do
    alter table(:damage_types) do
      add :reverse_stat, :string
      add :reverse_boost, :integer
    end

    execute  "update damage_types set reverse_stat = 'strength', reverse_boost = 20;"

    alter table(:damage_types) do
      modify :reverse_stat, :string, null: false
      modify :reverse_boost, :integer, null: false
    end
  end

  def down do
    alter table(:damage_types) do
      remove :reverse_stat
      remove :reverse_boost
    end
  end
end
