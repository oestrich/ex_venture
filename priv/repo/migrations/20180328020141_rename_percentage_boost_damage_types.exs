defmodule Data.Repo.Migrations.RenamePercentageBoostDamageTypes do
  use Ecto.Migration

  def change do
    rename table(:damage_types), :percentage_boost, to: :boost_ratio
  end
end
