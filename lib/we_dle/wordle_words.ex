defmodule WeDle.WordleWords do
  @moduledoc """
  Provides a task to load the official Wordle word lists into
  a performant in-memory cache (using `:persistent_term`), and
  helper functions to access the cache and validate a word's
  inclusion in the lists.

  ## Word lists

    * `:allowed` - The list of all possible words considered valid
    guesses as provided by the Wordle source code

    * `:answers` - The list of all possible Wordle answers as provided
    by the Wordle source code. `:answers` is a
    subset of `:allowed`.


  The cache warming task is run automatically at application startup.
  """

  use Task, restart: :transient

  @type word :: String.t()

  @doc """
  Starts and links a task to load the word lists from file and store
  them in a `:persistent_term` cache.

  This is automatically run in the top level supervision tree at
  startup. Any subsequent calls are effectively a noop as the new term
  should be equal to the old term. However, it is best to avoid
  calling this function outside of the application startup (or more than
  once in a node's lifetime), since if there are any changes then a global
  GC pass will be triggered. See `:persistent_term.put/2` for more info.

  ## Example

      # prefer to call this once by including it in a supervision tree

      children = [
        # ...
        WeDle.WordleWords,
        # ...
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
  """
  def start_link(_) do
    Task.start_link(&load_words/0)
  end

  @doc """
  Validates if the `word` is one of the allowed guesses according
  to the official Wordle source. Returns a boolean value.
  """
  @spec allowed_contains?(word) :: boolean
  def allowed_contains?(word), do: contains?(:allowed, word)

  @doc """
  Validates if the `word` is one of the possible answers according
  to the official Wordle source. Returns a boolean value.
  """
  @spec answers_contains?(word) :: boolean
  def answers_contains?(word), do: contains?(:answers, word)

  defp load_words do
    answers =
      "answers.txt"
      |> Path.absname(words_path())
      |> stream_file_and_map()

    allowed =
      "extras.txt"
      |> Path.absname(words_path())
      |> stream_file_and_map()
      |> Map.merge(answers)

    :persistent_term.put({__MODULE__, :answers}, answers)
    :persistent_term.put({__MODULE__, :allowed}, allowed)
  end

  defp words_path do
    # In production deployments the working directory is app/bin,
    # and our word files have a different relative path than they
    # do in our source code
    case File.cwd!() do
      "/app/bin" -> "../words"
      _ -> "./words"
    end
  end

  defp stream_file_and_map(path) do
    path
    |> File.stream!(encoding: :utf8)
    |> Stream.map(&{String.trim(:binary.copy(&1), "\n"), true})
    |> Enum.into(%{})
  end

  defp contains?(bucket, word) do
    {__MODULE__, bucket}
    |> :persistent_term.get()
    |> Map.get(word, false)
  end
end
