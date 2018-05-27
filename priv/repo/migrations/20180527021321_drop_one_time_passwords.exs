defmodule Data.Repo.Migrations.DropOneTimePasswords do
  use Ecto.Migration

  def change do
    drop table(:one_time_passwords)
  end
end
