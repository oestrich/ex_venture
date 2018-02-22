defmodule Data.Repo.Migrations.AddUniqueIndexToOtps do
  use Ecto.Migration

  def change do
    create index(:one_time_passwords, :password, unique: true)
  end
end
