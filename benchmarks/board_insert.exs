defmodule NewBoard do
  defstruct [
    :word_length,
    rows: [[], [], [], [], [], []],
    turns: 0
  ]

  def new(word_length)
      when is_integer(word_length) and word_length >= 3 and word_length <= 10 do
    struct!(__MODULE__, word_length: word_length)
  end

  def insert(%__MODULE__{} = board, guess, target)
      when is_binary(guess) and is_binary(target) do
    guess_graphs = String.graphemes(guess)
    with :ok <- validate_word_length(guess_graphs, board.word_length),
         :ok <- validate_board_is_not_full(board) do
      target_graphs = String.graphemes(target)

      guess_graphs
      |> compare(target_graphs)
      |> insert(board)
    end
  end

  defp insert(comparison, %{rows: rows, turns: turns} = board) do
    %{
      board |
        rows: List.replace_at(rows, turns, comparison),
        turns: turns + 1
    }
  end

  defp validate_word_length(guess_graphs, word_length) when length(guess_graphs) == word_length,
    do: :ok

  defp validate_word_length(_, _), do: {:error, :invalid_word_length}

  defp validate_board_is_not_full(%{turns: turns}) when turns < 6, do: :ok
  defp validate_board_is_not_full(%{turns: _turns}), do: {:error, :board_full}

  defp compare(guess_graphs, target_graphs) do
    case guess_graphs == target_graphs do
      true ->
        Enum.map(guess_graphs, &{0, &1})

      false ->
        compare_letters(guess_graphs, target_graphs)
    end
  end

  defp compare_letters(guess_graphs, target_graphs) do
    max_index = length(guess_graphs) - 1

    guess_graphs
    |> compare_exact_matches(target_graphs, max_index)
    |> compare_possible_matches(target_graphs, max_index)
    |> Map.get(:comps)
  end

  defp compare_exact_matches(guess_graphs, target_graphs, max_index) do
    Enum.reduce(0..max_index, %{distro: %{}, comps: []}, fn i, acc ->
      graph = Enum.at(guess_graphs, i)
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

defmodule OldBoard do
  defstruct [
    :word_length,
    rows: [[], [], [], [], [], []]
  ]

  def new(word_length)
      when is_integer(word_length) and word_length >= 3 and word_length <= 10 do
    struct!(__MODULE__, word_length: word_length)
  end

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

new_board = NewBoard.new(5)

new_board_insert = fn ->
  new_board
  |> NewBoard.insert("hello", "world")
  |> NewBoard.insert("aaaaa", "world")
  |> NewBoard.insert("worlf", "world")
  |> NewBoard.insert("dlrow", "world")
  |> NewBoard.insert("where", "world")
  |> NewBoard.insert("world", "world")
end

old_board = OldBoard.new(5)

old_board_insert = fn ->
  old_board
  |> OldBoard.insert("hello", "world")
  |> OldBoard.insert("aaaaa", "world")
  |> OldBoard.insert("worlf", "world")
  |> OldBoard.insert("dlrow", "world")
  |> OldBoard.insert("where", "world")
  |> OldBoard.insert("world", "world")
end

Benchee.run(
  %{
    "new_board" => new_board_insert,
    "old_board" => old_board_insert
  },
  time: 10,
  memory_time: 2,
  reduction_time: 2,
  formatters: [
    Benchee.Formatters.HTML,
    Benchee.Formatters.Console
  ]
)

# Operating System: macOS
# CPU Information: Intel(R) Core(TM) i7-4771 CPU @ 3.50GHz
# Number of Available Cores: 8
# Available memory: 32 GB
# Elixir 1.13.4
# Erlang 24.3.4

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 2 s
# reduction time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 32 s

# Benchmarking new_board ...
# Benchmarking old_board ...
# Generated benchmarks/output/results.html
# Generated benchmarks/output/results_comparison.html
# Generated benchmarks/output/results_new_board.html
# Generated benchmarks/output/results_old_board.html
# Opened report using open

# Name                ips        average  deviation         median         99th %
# new_board       66.98 K       14.93 μs    ±93.15%       13.66 μs       42.36 μs
# old_board       52.45 K       19.07 μs   ±153.40%       14.75 μs       75.75 μs

# Comparison:
# new_board       66.98 K
# old_board       52.45 K - 1.28x slower +4.14 μs

# Memory usage statistics:

# Name         Memory usage
# new_board        19.63 KB
# old_board        18.70 KB - 0.95x memory usage -0.92188 KB

# **All measurements for memory usage were the same**

# Reduction count statistics:

# Name      Reduction count
# new_board          1.95 K
# old_board          2.52 K - 1.30x reduction count +0.57 K

# **All measurements for reduction count were the same**
