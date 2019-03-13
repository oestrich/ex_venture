defmodule Data.Repo.Migrations.PgNotifyHelpTopics do
  use Ecto.Migration

  def change do
    execute("""
    CREATE TRIGGER config_changed
    AFTER INSERT OR UPDATE
    ON help_topics
    FOR EACH ROW
    EXECUTE PROCEDURE notify_row_changes()
    """)
  end
end
