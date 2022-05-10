defmodule WeDle.Game.Board do
  @moduledoc """
  This module provides an API for transforming the
  game board struct.
  """

  defstruct [
    :word_length,
    rows: [[], [], [], [], [], []]
  ]

  @type row_entry :: {non_neg_integer, String.t()}
  @type row :: [row_entry]
  @type t :: %__MODULE__{
          word_length: pos_integer,
          rows: [row]
        }

  @doc """
  Constructs a new board with the given `word_length`.

  `word_length` must an integer between `3` and `10`.

  ## Examples

        iex> WeDle.Game.Board.new(8)
        %WeDle.Game.Board{rows: [[], [], [], [], [], []], word_length: 8}
  """
  @spec new(3 | 4 | 5 | 6 | 7 | 8 | 9 | 10) :: __MODULE__.t()
  def new(word_length)
      when is_integer(word_length) and word_length >= 3 and word_length <= 10 do
    struct!(__MODULE__, word_length: word_length)
  end

  @doc """
  Inserts a comparison between the `guess` and the `target`
  into the board and computes the results.

  Results are inserted into the next empty row. Each individual
  letter is represented by a two-element tuple in the form
  `{distance, letter}` where `distance` is the degree of divergence
  from the target.

  ## Distance values

    * `0` - Indicates that the letter and its placement match
  the target exactly

    * `1` - indicates that the letter is in the target but in the
    wrong position, and the number of occurrences has not exceeded
    that of the target

    * `2` - indicates that either letter is not contained within the
    target at all, or that the letter has already occurred and the
    occurrence exceeds that of the target

  ## Examples

      iex> board = WeDle.Game.Board.new(5)
      iex> WeDle.Game.Board.insert(board, "hello", "world")
      %WeDle.Game.Board{
        rows: [[{2, "h"}, {2, "e"}, {2, "l"}, {0, "l"}, {1, "o"}], [], [], [], [], []],
        word_length: 5
      }

      iex> WeDle.Game.Board.new(5) |> WeDle.Game.Board.insert("hello", "hello")
      %WeDle.Game.Board{
        rows: [[{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}], [], [], [], [], []],
        word_length: 5
      }
  """
  def insert(%__MODULE__{} = board, guess, target)
      when is_binary(guess) and is_binary(target) do
    with :ok <- validate_word_length(guess, board.word_length),
         :ok <- validate_board_is_not_full(board) do
      guess
      |> compare(target)
      |> insert(board)
    end
  end

  defp insert(comparison, board) do
    Enum.reduce_while(0..5, board, fn i, brd ->
      if Enum.at(brd.rows, i) == [] do
        rows = List.replace_at(brd.rows, i, comparison)
        {:halt, %{brd | rows: rows}}
      else
        {:cont, brd}
      end
    end)
  end

  defp validate_word_length(guess, word_length) do
    case length(to_charlist(guess)) == word_length do
      true -> :ok
      false -> {:error, :invalid_word_length}
    end
  end

  defp validate_board_is_not_full(board) do
    board
    |> Map.get(:rows)
    |> Enum.any?(&(&1 == []))
    |> case do
      true -> :ok
      false -> {:error, :board_full}
    end
  end

  defp compare(guess, target) do
    case guess == target do
      true ->
        guess
        |> to_charlist()
        |> Enum.map(&{0, to_string([&1])})

      false ->
        compare_letters(guess, target)
    end
  end

  defp compare_letters(guess, target) do
    target_chars = to_charlist(target)
    guess_chars = to_charlist(guess)
    max_index = length(guess_chars) - 1

    guess_chars
    |> compare_exact_matches(target_chars, max_index)
    |> compare_possible_matches(target_chars, max_index)
    |> Map.get(:comps)
  end

  defp compare_exact_matches(guess_chars, target_chars, max_index) do
    Enum.reduce(0..max_index, %{distro: %{}, comps: []}, fn i, acc ->
      char = Enum.at(guess_chars, i)
      target_char = Enum.at(target_chars, i)

      if char == target_char do
        comp = {0, to_string([char])}
        comps = List.insert_at(acc.comps, -1, comp)
        distro = Map.update(acc.distro, char, 1, &(&1 + 1))
        %{acc | distro: distro, comps: comps}
      else
        comp = {:cont, char}
        comps = List.insert_at(acc.comps, -1, comp)
        %{acc | comps: comps}
      end
    end)
  end

  defp compare_possible_matches(first_pass, target_chars, max_index) do
    target_distro =
      Enum.reduce(target_chars, %{}, fn char, acc ->
        Map.update(acc, char, 1, &(&1 + 1))
      end)

    Enum.reduce(0..max_index, first_pass, fn i, %{distro: distro, comps: comps} = acc ->
      case Enum.at(comps, i) do
        {:cont, char} -> compare_possible_match(acc, i, comps, char, distro, target_distro)
        {char, _} when is_integer(char) -> acc
      end
    end)
  end

  defp compare_possible_match(acc, i, comps, char, distro, target_distro) do
    if Map.get(distro, char, 0) < Map.get(target_distro, char, 0) do
      comp = {1, to_string([char])}
      comps = List.replace_at(comps, i, comp)
      distro = Map.update(distro, char, 1, &(&1 + 1))
      %{acc | distro: distro, comps: comps}
    else
      comp = {2, to_string([char])}
      comps = List.replace_at(comps, i, comp)
      %{acc | comps: comps}
    end
  end
end
