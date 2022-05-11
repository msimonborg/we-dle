defmodule WeDle.Game.Board do
  @moduledoc """
  This module provides an API for transforming the
  game board struct.
  """

  defstruct [
    :word_length,
    rows: [[], [], [], [], [], []],
    turns: 0
  ]

  @type row_entry :: {0 | 1 | 2, String.t()}
  @type row :: [row_entry]
  @type turn :: 0 | 1 | 2 | 3 | 4 | 5 | 6
  @type t :: %__MODULE__{
          word_length: 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10,
          rows: [row],
          turns: turn
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
  Inserts a comparison between the `word` and the `target`
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
        word_length: 5,
        turns: 1
      }

      iex> WeDle.Game.Board.new(5) |> WeDle.Game.Board.insert("hello", "hello")
      %WeDle.Game.Board{
        rows: [[{0, "h"}, {0, "e"}, {0, "l"}, {0, "l"}, {0, "o"}], [], [], [], [], []],
        word_length: 5,
        turns: 1
      }
  """
  def insert(%__MODULE__{} = board, word, target)
      when is_binary(word) and is_binary(target) do
    graphs = String.graphemes(word)

    with :ok <- validate_word_length(graphs, board.word_length),
         :ok <- validate_board_is_not_full(board) do
      target_graphs = String.graphemes(target)

      graphs
      |> compare(target_graphs)
      |> insert(board)
    end
  end

  defp insert(comparison, %{rows: rows, turns: turns} = board) do
    %{
      board
      | rows: List.replace_at(rows, turns, comparison),
        turns: turns + 1
    }
  end

  defp validate_word_length(graphs, word_length) when length(graphs) == word_length,
    do: :ok

  defp validate_word_length(_, _), do: {:error, :invalid_word_length}

  defp validate_board_is_not_full(%{turns: turns}) when turns < 6, do: :ok
  defp validate_board_is_not_full(%{turns: _turns}), do: {:error, :board_full}

  defp compare(graphs, target_graphs) when graphs == target_graphs,
    do: Enum.map(graphs, &{0, &1})

  defp compare(graphs, target_graphs),
    do: compare_letters(graphs, target_graphs)

  defp compare_letters(graphs, target_graphs) do
    max_index = length(graphs) - 1

    graphs
    |> compare_exact_matches(target_graphs, max_index)
    |> compare_possible_matches(target_graphs, max_index)
    |> Map.get(:comps)
  end

  defp compare_exact_matches(graphs, target_graphs, max_index) do
    Enum.reduce(0..max_index, %{distro: %{}, comps: []}, fn i, acc ->
      graph = Enum.at(graphs, i)
      target_graph = Enum.at(target_graphs, i)

      if graph == target_graph do
        comps = List.insert_at(acc.comps, -1, {0, graph})
        distro = Map.update(acc.distro, graph, 1, &(&1 + 1))
        %{acc | distro: distro, comps: comps}
      else
        comps = List.insert_at(acc.comps, -1, {:cont, graph})
        %{acc | comps: comps}
      end
    end)
  end

  defp compare_possible_matches(first_pass, target_graphs, max_index) do
    target_distro = Enum.frequencies(target_graphs)

    Enum.reduce(0..max_index, first_pass, fn i, %{distro: distro, comps: comps} = acc ->
      case Enum.at(comps, i) do
        {:cont, graph} -> compare_possible_match(acc, i, comps, graph, distro, target_distro)
        {_, _} -> acc
      end
    end)
  end

  defp compare_possible_match(acc, i, comps, graph, distro, target_distro) do
    if Map.get(distro, graph, 0) < Map.get(target_distro, graph, 0) do
      comps = List.replace_at(comps, i, {1, graph})
      distro = Map.update(distro, graph, 1, &(&1 + 1))
      %{acc | distro: distro, comps: comps}
    else
      comps = List.replace_at(comps, i, {2, graph})
      %{acc | comps: comps}
    end
  end
end
