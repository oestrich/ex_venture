defmodule Data.Repo.Migrations.AddTimeOnlineToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :seconds_online, :integer, default: 0, null: false
    end
  end
end
