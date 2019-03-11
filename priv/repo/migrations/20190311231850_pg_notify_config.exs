defmodule Data.Repo.Migrations.PgNotifyConfig do
  use Ecto.Migration

  def change do
    execute("""
    CREATE TRIGGER config_changed
    AFTER INSERT OR UPDATE
    ON config
    FOR EACH ROW
    EXECUTE PROCEDURE notify_row_changes()
    """)
  end
end
