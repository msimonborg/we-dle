defmodule WeDle.WordleWordsTest do
  use ExUnit.Case, async: true

  import WeDle.WordleWords

  defp answers do
    "./words/answers.txt"
    |> File.stream!(encoding: :utf8)
    |> Enum.map(&String.trim(:binary.copy(&1), "\n"))
  end

  defp allowed do
    "./words/answers.txt"
    |> File.stream!(encoding: :utf8)
    |> Enum.map(&String.trim(:binary.copy(&1), "\n"))
    |> List.flatten(answers())
  end

  test "todays_answer?/1 validates words correctly" do
    map =
      for word <- answers(), reduce: %{} do
        acc -> Map.put(acc, word, todays_answer?(word))
      end

    assert Enum.count(map, fn {_word, bool} -> not bool end) == map_size(map) - 1
    assert Enum.count(map, fn {_word, bool} -> bool end) == 1
    assert Map.get(map, todays_answer()) == true
  end

  test "allowed?/1 validates words correctly" do
    for word <- allowed() do
      assert allowed?(word)
      refute allowed?(word <> "!")
    end
  end
end
