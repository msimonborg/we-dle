defmodule WeDle.Repo.Local.Migrations.AlwaysEnableHandoffNotifications do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE handoffs ENABLE ALWAYS TRIGGER handoff_inserted;
    """)
  end
end
