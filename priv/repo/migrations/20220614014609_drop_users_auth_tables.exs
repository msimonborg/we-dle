defmodule WeDle.Repo.Migrations.DropUsersAuthTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:users_tokens)
    drop_if_exists table(:users)
  end
end
