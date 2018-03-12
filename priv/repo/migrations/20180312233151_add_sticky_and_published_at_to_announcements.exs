defmodule Data.Repo.Migrations.AddStickyAndPublishedAtToAnnouncements do
  use Ecto.Migration

  def change do
    alter table(:announcements) do
      add :is_sticky, :boolean, default: false, null: false
      add :published_at, :utc_datetime, default: fragment("now()"), null: false
    end
  end
end
