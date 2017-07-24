defmodule Data.Repo.Migrations.RenameUsernameToNameOnUsers do
  use Ecto.Migration

  def up do
    rename table(:users), :username, to: :name
    execute "alter index users_username_index rename to users_name_index;"
  end

  def down do
    rename table(:users), :name, to: :username
    execute "alter index users_name_index rename to users_username_index;"
  end
end
