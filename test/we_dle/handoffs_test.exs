defmodule WeDle.HandoffsTest do
  use WeDle.DataCase, async: true

  import WeDle.Handoffs

  alias WeDle.{Game, Game.Board, Game.Player, Schemas.Handoff}

  setup :build_game

  describe "create_handoff/1" do
    test "can create a valid WeDle.Schemas.Handoff from a WeDle.Game struct", %{game: game} do
      assert {:ok, handoff} = create_handoff(game)
      assert handoff.game_id == game.id
      assert handoff.word_length == game.word_length
      assert handoff.started_at == game.started_at
      assert handoff.player1_challenge == "hello"
      assert handoff.player1_id == "player1"
      assert handoff.player1_rows == "world\n\n\n\n\n"
      assert handoff.player2_challenge == "world"
      assert handoff.player2_id == "player2"
      assert handoff.player2_rows == "hello\n\n\n\n\n"
    end

    test "returns an error changeset with invalid data", %{game: game} do
      assert {:error, changeset} = create_handoff(%Game{})
      assert {"can't be blank", _} = changeset.errors[:game_id]
      assert {"can't be blank", _} = changeset.errors[:word_length]
      assert {"can't be blank", _} = changeset.errors[:started_at]

      assert {:error, changeset} = create_handoff(%Game{word_length: 11})
      assert {"is invalid", _} = changeset.errors[:word_length]

      assert {:ok, _} = create_handoff(game)
      assert {:error, changeset} = create_handoff(%Game{id: game.id, word_length: 5})
      assert {"has already been taken", _} = changeset.errors[:game_id]

      expiration_time = WeDle.Schemas.Handoff.expiration_time(:second)
      old_time = DateTime.add(DateTime.utc_now(), -(expiration_time + 1), :second)
      assert {:error, changeset} = create_handoff(%{game | started_at: old_time})
      assert {"can't be over twenty-four hours old", _} = changeset.errors[:started_at]
    end
  end

  describe "get_handoff/1" do
    test "can get a handoff by its game_id", %{game: game} do
      assert {:ok, handoff} = create_handoff(game)
      assert get_handoff(game.id) == handoff
    end
  end

  describe "list_handoffs/0" do
    test "returns a list of all handoffs in the database", %{game: game} do
      assert {:ok, handoff} = create_handoff(game)
      assert [^handoff] = list_handoffs()
    end
  end

  describe "delete_handoff/1" do
    test "deletes the given handoff from the database", %{game: game} do
      assert {:ok, handoff} = create_handoff(game)
      assert %Handoff{} = delete_handoff!(handoff)
      assert game.id |> get_handoff() |> is_nil()
    end
  end

  describe "delete_all_handoffs/0" do
    test "deletes all handoffs from the database", %{game: game} do
      assert {:ok, _} = create_handoff(game)
      assert delete_all_handoffs() == 1
      assert game.id |> get_handoff() |> is_nil()
    end
  end

  describe "delete_handoffs_older_than/2" do
    test "deletes all handoffs from the database odler than the given time", %{game: game} do
      assert {:ok, handoff} = create_handoff(game)

      Process.sleep(2_000)

      assert delete_handoffs_older_than(2, :second) == 0
      assert get_handoff(game.id) == handoff

      assert delete_handoffs_older_than(1, :second) == 1
      assert game.id |> get_handoff() |> is_nil()
    end
  end

  describe "delete_handoff_if_exists/1" do
    test "deletes the handoff with the given game_id if it exists", %{game: game} do
      assert {:ok, _} = create_handoff(game)

      assert delete_handoff_if_exists(game.id)
      assert not delete_handoff_if_exists(game.id)
    end
  end

  defp build_game(_) do
    game_id = "handoff_test"
    word_length = 5
    board = Board.new(word_length)

    player1 =
      Player.new(
        id: "player1",
        game_id: game_id,
        board: Board.insert(board, "world", "world"),
        challenge: "hello"
      )

    player2 =
      Player.new(
        id: "player2",
        game_id: game_id,
        board: Board.insert(board, "hello", "hello"),
        challenge: "world"
      )

    game = %Game{
      id: game_id,
      word_length: word_length,
      started_at: DateTime.utc_now(),
      players: %{"player1" => player1, "player2" => player2}
    }

    %{game: game}
  end
end
