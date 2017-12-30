defmodule Data.Repo.Migrations.AddUniqueIndexOnEmails do
  use Ecto.Migration

  def change do
    create index(:users, :email, unique: true)
  end
end
