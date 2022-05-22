defmodule WeDle.Repo.Migrations.CreateHandoffs do
  use Ecto.Migration

  def change do
    create table("handoffs") do
      add :game_id, :string, null: false
      add :word_length, :integer, null: false
      add :player1_id, :string
      add :player1_challenge, :string
      add :player1_rows, :string
      add :player2_id, :string
      add :player2_challenge, :string
      add :player2_rows, :string

      timestamps()
    end

    create unique_index("handoffs", [:game_id])
  end
end
