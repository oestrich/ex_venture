defmodule Data.Repo.Migrations.AddStatusListenToNpcs do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      add :status_listen, :string
    end
  end
end
