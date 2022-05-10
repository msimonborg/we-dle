defmodule NewBoard do
  defstruct [
    :word_length,
    rows: {[], [], [], [], [], []}
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
      if elem(brd.rows, i) == [] do
        rows = put_elem(brd.rows, i, comparison)
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
    case elem(board.rows, 5) == [] do
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
  memory_time: 2
)
