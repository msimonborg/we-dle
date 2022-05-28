defmodule WeDle.WordleWords do
  @moduledoc """
  Provides a task to load the official Wordle word collections into
  a performant in-memory cache (using `:persistent_term`), and
  helper functions to access the cache and validate a word against
  the collections.

  ## Word lists

    * `:allowed` - The collection of all possible words considered valid
    guesses as provided by the Wordle source code. This collection
    is a map in the shape `%{word => true, ...}`.

    * `:answers` - The collection of all possible Wordle answers as
    provided by the Wordle source code. `:answers` is a subset of
    `:allowed`. This collection is a map in the shape
    `%{index => word, ...}`.


  The cache warming task is run automatically at application startup.

  ## Why use `:persistent_term`?

  The goal is a fast and performant cache of the official Wordle words,
  avoiding unnecessary transactions with the database or HTTP requests
  for the data.

  Currently we're using `:persistent_term` to store two data structures
  that contain the lists of valid answers and possible guesses.
  `:persistent_term` makes these data structures accessible concurrently
  by any local process in constant near-zero time, and is optimized for
  data that rarely or never changes.

  The downside to this approach as I see it is the requirement to copy
  the word files to the final release image in production so they can
  be loaded at runtime, adding to the number and size of build artifacts.

  At least one other approach might be to load the data at compile
  time and dynamically store it in code. This would allow us to use the
  files only while building the release and exclude them from the final
  image.

  My thinking, which may likely be wrong, is that while this approach
  would cut down slightly on the image size, it would require the entire data
  structure to be copied to the heap of any process that uses it. At scale
  this could potentially be thousands of concurrent processes representing
  individual users.

  Using `:persistent_term` allows access to the data as a shared reference
  and adds nothing to the heap of a process that needs access to the data.
  """

  use Task, restart: :transient

  @type word :: String.t()

  # The start date to count from when calculating the index of today's word.
  @start_date ~D[2021-06-19]

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
  to the official Wordle source.

  Returns a boolean value.
  """
  @spec allowed?(word) :: boolean
  def allowed?(word) do
    {__MODULE__, :allowed}
    |> :persistent_term.get()
    |> Map.get(word, false)
  end

  @doc """
  Validates if the `word` is today's official Wordle answer.

  Returns a boolean value.
  """
  @spec todays_answer?(word) :: boolean
  def todays_answer?(word), do: word == todays_answer()

  @doc """
  Returns today's official Wordle answer.
  """
  @spec todays_answer :: word
  def todays_answer do
    diff = Date.diff(Date.utc_today(), @start_date)

    {__MODULE__, :answers}
    |> :persistent_term.get()
    |> Map.get(diff)
  end

  defp load_words do
    answers_stream =
      "answers.txt"
      |> Path.absname(words_path())
      |> File.stream!(encoding: :utf8)

    answers =
      answers_stream
      |> Stream.map(&String.trim(:binary.copy(&1), "\n"))
      |> Stream.with_index()
      |> Stream.map(fn {v, i} -> {i, v} end)
      |> Enum.into(%{})

    allowed =
      "extras.txt"
      |> Path.absname(words_path())
      |> File.stream!(encoding: :utf8)
      |> stream_and_map()
      |> Map.merge(stream_and_map(answers_stream))

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

  defp stream_and_map(stream) do
    stream
    |> Stream.map(&{String.trim(:binary.copy(&1), "\n"), true})
    |> Enum.into(%{})
  end
end
