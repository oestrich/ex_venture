defmodule Data.Repo.Migrations.NameMapLayersInAdmin do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :map_layer_names, :jsonb, default: fragment("'{}'"), null: false
    end
  end
end
