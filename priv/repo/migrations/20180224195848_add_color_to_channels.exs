defmodule Data.Repo.Migrations.AddColorToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :color, :string, default: "red", null: false
    end
  end
end
