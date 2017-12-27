defmodule Data.Repo.Migrations.AddNotesToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :notes, :string
    end
  end
end
