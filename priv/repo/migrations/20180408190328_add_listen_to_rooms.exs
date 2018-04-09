defmodule Data.Repo.Migrations.AddListenToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :listen, :string
    end
  end
end
