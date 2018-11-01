defmodule Data.Repo.Migrations.FixUniqueIndexOnUsers do
  use Ecto.Migration

  def up do
    create index(:users, ["lower(name)"], unique: true)
  end
end
