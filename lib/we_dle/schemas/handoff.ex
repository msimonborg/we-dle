defmodule WeDle.Schemas.Handoff do
  @moduledoc """
  The database schema for the `handoffs` table.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias WeDle.{Game, Repo}

  schema "handoffs" do
    field :game_id, :string
    field :word_length, :integer
    field :player1_id, :string
    field :player1_challenge, :string
    field :player1_rows, :string
    field :player2_id, :string
    field :player2_challenge, :string
    field :player2_rows, :string

    timestamps()
  end

  @fields [
    :game_id,
    :word_length,
    :player1_id,
    :player1_challenge,
    :player1_rows,
    :player2_id,
    :player2_challenge,
    :player2_rows
  ]

  @doc """
  Receives a `WeDle.Game` struct and returns an `Ecto.Changeset`
  for the handoff schema.
  """
  def changeset_from_game(%Game{} = game) do
    handoff = build_handoff_from_game(game)

    %__MODULE__{}
    |> cast(handoff, @fields)
    |> validate_required([:game_id, :word_length])
    |> unsafe_validate_unique([:game_id], Repo)
    |> validate_inclusion(:word_length, 3..10)
  end

  defp build_handoff_from_game(game) do
    players = Enum.map(game.players, fn {_, player} -> player end)

    %{
      game_id: game.id,
      word_length: game.word_length
    }
    |> maybe_add_players(players)
  end

  defp maybe_add_players(handoff, players) do
    player1 = List.first(players)

    if player1 do
      Map.merge(handoff, %{
        player1_id: player1.id,
        player1_challenge: player1.challenge,
        player1_rows: extract_rows(player1)
      })
      |> maybe_add_player2(players)
    else
      handoff
    end
  end

  defp maybe_add_player2(handoff, players) do
    player2 = List.last(players)

    if player2 do
      Map.merge(handoff, %{
        player2_id: player2.id,
        player2_challenge: player2.challenge,
        player2_rows: extract_rows(player2)
      })
    else
      handoff
    end
  end

  defp extract_rows(player) do
    Enum.map_join(player.board.rows, "\n", fn row ->
      Enum.map_join(row, fn {_, char} -> char end)
    end)
  end
end
