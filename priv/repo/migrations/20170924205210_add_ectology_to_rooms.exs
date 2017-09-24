defmodule Data.Repo.Migrations.AddEctologyToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :ecology, :string, default: "default", null: false
    end
  end
end
