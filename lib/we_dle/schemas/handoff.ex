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
    field :started_at, :utc_datetime_usec
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
    :started_at,
    :player1_id,
    :player1_challenge,
    :player1_rows,
    :player2_id,
    :player2_challenge,
    :player2_rows
  ]

  @doc """
  Receives a `WeDle.Game` struct and returns an `Ecto.Changeset`
  for the `WeDle.Schemas.Handoff` schema.
  """
  @spec changeset_from_game(Game.t()) :: Ecto.Changeset.t()
  def changeset_from_game(%Game{} = game) do
    handoff = build_handoff_from_game(game)

    %__MODULE__{}
    |> cast(handoff, @fields)
    |> validate_required([:game_id, :word_length, :started_at])
    |> unsafe_validate_unique([:game_id], Repo)
    |> validate_inclusion(:word_length, 3..10)
    |> validate_change(:started_at, &validate_lt_twenty_four_hours_old/2)
  end

  defp validate_lt_twenty_four_hours_old(:started_at, started_at) do
    twenty_four_hours = 24 * 60 * 60
    diff = DateTime.diff(DateTime.utc_now(), started_at, :second)

    if diff >= twenty_four_hours do
      [started_at: "can't be over twenty-four hours old"]
    else
      []
    end
  end

  defp build_handoff_from_game(game) do
    players = Enum.map(game.players, fn {_, player} -> player end)

    %{
      game_id: game.id,
      word_length: game.word_length,
      started_at: game.started_at
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
      Enum.map_join(row, fn {_, grapheme} -> grapheme end)
    end)
  end
end
