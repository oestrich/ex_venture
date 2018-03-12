defmodule Data.Repo.Migrations.RenameHealthFields do
  use Ecto.Migration

  def change do
    rename table(:classes), :regen_health, to: :regen_health_points
  end
end
