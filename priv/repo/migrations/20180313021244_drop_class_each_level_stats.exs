defmodule Data.Repo.Migrations.DropClassEachLevelStats do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      remove :each_level_stats
    end
  end

  def down do
    raise "Sorry, no down"
  end
end
