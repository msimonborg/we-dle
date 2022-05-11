defmodule WeDle.Game.BoardTest do
  use ExUnit.Case, async: true

  alias WeDle.Game.Board

  doctest Board

  describe "new/1" do
    test "creates a `Board` struct with desired word length" do
      assert %Board{word_length: 8} = Board.new(8)
      assert %Board{word_length: 3} = Board.new(3)
    end
  end

  describe "insert/3" do
    test "sequentially adds rows with each insert" do
      board = Board.new(5) |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [],
               [],
               [],
               [],
               []
             ]

      assert board.turns == 1

      board = board |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [],
               [],
               [],
               []
             ]

      assert board.turns == 2

      board = board |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [],
               [],
               []
             ]

      assert board.turns == 3

      board = board |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [],
               []
             ]

      assert board.turns == 4

      board = board |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               []
             ]

      assert board.turns == 5

      board = board |> Board.insert("hello", "hello")

      assert board.rows == [
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}],
               [{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}]
             ]

      assert board.turns == 6
    end

    test "returns an error when the board is full" do
      board = Board.new(5)

      board =
        board
        |> Board.insert("hello", "world")
        |> Board.insert("hello", "world")
        |> Board.insert("hello", "world")
        |> Board.insert("hello", "world")
        |> Board.insert("hello", "world")
        |> Board.insert("hello", "world")

      assert board.rows == [
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}]
             ]

      assert board |> Board.insert("hello", "world") == {:error, :board_full}
    end

    test "can accurately analyze letter comparisons" do
      board =
        Board.new(5)
        |> Board.insert("hello", "world")
        |> Board.insert("aaaaa", "world")
        |> Board.insert("worlf", "world")
        |> Board.insert("dlrow", "world")
        |> Board.insert("wîøåü", "world")
        |> Board.insert("wîøåü", "wîøåü")

      assert board.rows == [
               [{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}],
               [{2, "a"}, {2, "a"}, {2, "a"}, {2, "a"}, {2, "a"}],
               [{0, "w"}, {0, "o"}, {0, "r"}, {0, "l"}, {2, "f"}],
               [{1, "d"}, {1, "l"}, {0, "r"}, {1, "o"}, {1, "w"}],
               [{0, "w"}, {2, "î"}, {2, "ø"}, {2, "å"}, {2, "ü"}],
               [{0, "w"}, {0, "î"}, {0, "ø"}, {0, "å"}, {0, "ü"}]
             ]
    end
  end
end
