defmodule Data.Repo.Migrations.AddPublishedToAnnouncements do
  use Ecto.Migration

  def change do
    alter table(:announcements) do
      add :is_published, :boolean, default: false, null: false
    end
  end
end
