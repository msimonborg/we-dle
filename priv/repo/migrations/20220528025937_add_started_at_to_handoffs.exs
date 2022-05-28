defmodule WeDle.Repo.Migrations.AddStartedAtToHandoffs do
  use Ecto.Migration

  def change do
    alter table("handoffs") do
      add :started_at, :utc_datetime_usec, null: false
    end
  end
end
