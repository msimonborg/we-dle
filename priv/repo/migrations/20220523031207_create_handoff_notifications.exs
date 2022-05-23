defmodule WeDle.Repo.Migrations.CreateHandoffNotifications do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_handoff_insertions()
    RETURNS trigger AS $$
    BEGIN
      PERFORM pg_notify(
        'handoff_inserted',
        NEW.game_id::text
      );

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER handoff_inserted
    AFTER INSERT
    ON handoffs
    FOR EACH ROW
    EXECUTE PROCEDURE notify_handoff_insertions();
    """)
  end

  def down do
    execute("DROP FUNCTION notify_handoff_insertions() CASCADE;")
  end
end
