defmodule WeDle.Game do
  @moduledoc """
  The public API for starting and stopping games, and game logic.
  """

  require Logger

  alias WeDle.Game.{
    DistributedRegistry,
    DistributedSupervisor,
    Player,
    Server
  }

  defstruct [:id, :word_length, :winner, players: %{}]

  @type id :: String.t()
  @type option :: {:word_length, pos_integer}
  @type options :: [option]
  @type t :: %__MODULE__{
          id: id,
          word_length: pos_integer,
          players: %{integer => Player.t()},
          winner: Player.t() | nil
        }

  @doc """
  Starts a new game.

  Returns `{:ok, pid}` on success, or `:ignore` if the game is already started.

  ## Options

    * `:word_length` - the word length for the challenge, defaults to 5

  ## Examples

      iex> {:ok, pid} = WeDle.Game.start("game")
      iex> is_pid(pid)
      true

      iex> {:ok, _pid} = WeDle.Game.start("other_game")
      iex> WeDle.Game.start("other_game")
      :ignore
  """
  @spec start(id) :: Server.on_start()
  def start(game_id, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:word_length, 5)
      |> Keyword.put(:game_id, game_id)

    DistributedSupervisor.start_child({Server, opts})
  end

  @doc """
  Joins a running game.

  Returns `{:ok, player}` where `player` is a `WeDle.Game.Player` struct representing
  the player that just joined, or `{:error, reason}`.

  ## Examples

      iex> WeDle.Game.start("diva_game")
      iex> {:ok, %WeDle.Game.Player{id: "Madonna"}} = WeDle.Game.join("diva_game", "Madonna")
      iex> {:error, :player_already_joined} = WeDle.Game.join("diva_game", "Madonna")
      iex> {:ok, %WeDle.Game.Player{id: "Tina"}} = WeDle.Game.join("diva_game", "Tina")
      iex> WeDle.Game.join("diva_game", "Sade")
      {:error, :game_full}
  """
  @spec join(id, id) :: {:ok, Player.t()} | {:error, term}
  def join(game_id, player_id) do
    GenServer.call(qualified_name(game_id), {:join_game, player_id})
  end

  @doc """
  Starts a new game if it's not already started, and automatically joins it.

  Returns `{:ok, player}` where `player` is a `WeDle.Game.Player` struct representing
  the player that just joined, or `{:error, reason}`.

  See `start/2` for available options.

  ## Examples

      iex> {:ok, %WeDle.Game.Player{id: "Nomar"}} = WeDle.Game.start_or_join("baseball_game", "Nomar")
      iex> {:error, :player_already_joined} = WeDle.Game.start_or_join("baseball_game", "Nomar")
      iex> {:ok, %WeDle.Game.Player{id: "Pedro"}} = WeDle.Game.start_or_join("baseball_game", "Pedro")
      iex> WeDle.Game.start_or_join("baseball_game", "Manny")
      {:error, :game_full}
  """
  @spec start_or_join(id, id, options) :: {:ok, Player.t()} | {:error, term}
  def start_or_join(game_id, player_id, opts \\ []) do
    case start(game_id, opts) do
      {:ok, _pid} -> join(game_id, player_id)
      :ignore -> join(game_id, player_id)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Set's the player with `player_id`'s challenge `word` for the other player.

  Returns `{:ok, player}` on success with the updates inserted into `player`.

  Returns `{:error, reason}` if the player did not join the game prior to
  calling this function or if the player's challenge word has previously been set.

  ## Examples

      iex> WeDle.Game.start_or_join("movie_game", "p1")
      iex> {:ok, %WeDle.Game.Player{challenge: "Rocky"}} = WeDle.Game.set_challenge("movie_game", "p1", "Rocky")
      iex> {:error, :player_not_found} = WeDle.Game.set_challenge("movie_game", "p5", "Forrest")
      iex> WeDle.Game.set_challenge("movie_game", "p1", "Titanic")
      {:error, :challenge_already_exists}
  """
  def set_challenge(game_id, player_id, word) when is_binary(word) and is_binary(player_id) do
    GenServer.call(qualified_name(game_id), {:set_challenge, word, player_id})
  end

  @doc """
  Submit's the player with `player_id`'s `word` for for comparison
  with the challenge word.

  Returns `{:ok, player}` on success with the updates inserted into `player`,
  otherwise returns `{:error, reason}`.

  ## Examples

      iex> WeDle.Game.start_or_join("spirits_game", "p1", word_length: 6)
      iex> WeDle.Game.start_or_join("spirits_game", "p2", word_length: 6)
      iex> WeDle.Game.set_challenge("spirits_game", "p1", "whisky")
      iex> {:ok, player} = WeDle.Game.submit_word("spirits_game", "p2", "scotch")
      iex> player.board.rows
      [[{1, "s"}, {2, "c"}, {2, "o"}, {2, "t"}, {2, "c"}, {1, "h"}], [], [], [], [], []]
      iex> WeDle.Game.submit_word("spirits_game", "p2", "gin")
      {:error, :invalid_word_length}
      iex> WeDle.Game.submit_word("spirits_game", "p3", "mezcal")
      {:error, :player_not_found}
  """
  def submit_word(game_id, player_id, word) when is_binary(word) and is_binary(player_id) do
    GenServer.call(qualified_name(game_id), {:submit_word, word, player_id})
  end

  defp qualified_name(game_id) when is_binary(game_id), do: DistributedRegistry.via_tuple(game_id)
end
