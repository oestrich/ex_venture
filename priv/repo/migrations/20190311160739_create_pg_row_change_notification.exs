defmodule Data.Repo.Migrations.CreatePgRowChangeNotification do
  use Ecto.Migration

  def change do
    execute("""
    CREATE OR REPLACE FUNCTION notify_row_changes()
    RETURNS trigger AS $$
    BEGIN
      PERFORM pg_notify(
        'row_changed',
        json_build_object(
          'table', TG_TABLE_NAME,
          'operation', TG_OP,
          'record', row_to_json(NEW)
        )::text
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER items_changed
    AFTER INSERT OR UPDATE
    ON items
    FOR EACH ROW
    EXECUTE PROCEDURE notify_row_changes()
    """)
  end
end
