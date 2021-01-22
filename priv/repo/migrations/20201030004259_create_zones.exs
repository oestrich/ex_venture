defmodule ExVenture.Repo.Migrations.CreateZones do
  use Ecto.Migration

  def change do
    create table(:zones) do
      add(:name, :string, null: false)
      add(:description, :text, default: "", null: false)

      add(:live_at, :utc_datetime)

      timestamps()
    end

    create table(:rooms) do
      add(:zone_id, references(:zones), null: false)

      add(:name, :string, null: false)
      add(:description, :text, null: false)
      add(:listen, :text, null: false)
      add(:features, {:array, :jsonb}, default: fragment("'{}'::jsonb[]"), null: false)

      add(:map_color, :string, default: "gray", null: false)
      add(:map_icon, :string, default: "default", null: false)

      add(:x, :integer, null: false)
      add(:y, :integer, null: false)
      add(:z, :integer, null: false)

      add(:notes, :text)

      add(:live_at, :utc_datetime)

      timestamps()
    end

    alter table(:zones) do
      add(:graveyard_id, references(:rooms))
    end
  end
end
