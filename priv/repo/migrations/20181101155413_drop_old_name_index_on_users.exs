defmodule Data.Repo.Migrations.DropOldNameIndexOnUsers do
  use Ecto.Migration

  def change do
    drop index(:users, :name)
  end
end
