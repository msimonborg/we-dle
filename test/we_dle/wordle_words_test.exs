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

  test "answers_contains?/1 validates words correctly" do
    for word <- answers() do
      assert answers_contains?(word)
      refute answers_contains?(word <> "!")
    end
  end

  test "allowed_contains?/1 validates words correctly" do
    for word <- allowed() do
      assert allowed_contains?(word)
      refute allowed_contains?(word <> "!")
    end
  end
end
