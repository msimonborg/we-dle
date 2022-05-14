defmodule WeDle.Game do
  @moduledoc """
  The public API for starting and stopping games, and game logic.
  """

  require Logger

  alias WeDle.Game.{
    DistributedRegistry,
    DistributedSupervisor,
    EdgeServer,
    EdgeSupervisor,
    Player,
    Server
  }

  defstruct [:id, :word_length, :winner, players: %{}, edge_servers: %{}]

  @type id :: String.t()
  @type option :: {:word_length, pos_integer}
  @type options :: [option]
  @type player :: Player.t()
  @type t :: %__MODULE__{
          id: id,
          word_length: pos_integer,
          players: %{id => player},
          edge_servers: %{id => %{ref: reference, pid: pid}},
          winner: player | nil
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
      iex> {:ok, %WeDle.Game.Player{id: "Tina"}} = WeDle.Game.join("diva_game", "Tina")
      iex> WeDle.Game.join("diva_game", "Sade")
      {:error, :player_not_found}
  """
  @spec join(id, id) :: {:ok, player} | {:error, term}
  def join(game_id, player_id) do
    case whereis(game_id) do
      pid when is_pid(pid) ->
        join(pid, game_id, player_id)

      nil ->
        {:error, :game_not_found}
    end
  end

  defp join(pid, game_id, player_id) do
    EdgeSupervisor.start_edge(game_id, player_id)
    EdgeServer.join_game(pid, game_id, player_id)
  end

  @doc """
  Starts a new game if it's not already started, and automatically joins it.

  Returns `{:ok, player}` where `player` is a `WeDle.Game.Player` struct representing
  the player that just joined, or `{:error, reason}`.

  See `start/2` for available options.

  ## Examples

      iex> {:ok, %WeDle.Game.Player{id: "Nomar"}} = WeDle.Game.start_or_join("baseball_game", "Nomar")
      iex> {:ok, %WeDle.Game.Player{id: "Pedro"}} = WeDle.Game.start_or_join("baseball_game", "Pedro")
      iex> WeDle.Game.start_or_join("baseball_game", "Manny")
      {:error, :player_not_found}
  """
  @spec start_or_join(id, id, options) :: {:ok, player} | {:error, term}
  def start_or_join(game_id, player_id, opts \\ []) do
    case start(game_id, opts) do
      {:ok, pid} -> join(pid, game_id, player_id)
      :ignore -> join(game_id, player_id)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Set's the player with `player_id`'s challenge `word` for the other player.

  Returns `{:ok, player}` on success with the updates inserted into `player`.

  Returns `{:error, reason}` if the player's challenge word has previously
  been set.

  ## Examples

      iex> WeDle.Game.start_or_join("movie_game", "p1")
      iex> {:ok, %WeDle.Game.Player{challenge: "Rocky"}} = WeDle.Game.set_challenge("movie_game", "p1", "Rocky")
      iex> WeDle.Game.set_challenge("movie_game", "p1", "Titanic")
      {:error, :challenge_already_exists}
  """
  def set_challenge(game_id, player_id, word) when is_binary(word) and is_binary(player_id) do
    GenServer.call(edge_name(game_id, player_id), {:set_challenge, word})
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
  """
  def submit_word(game_id, player_id, word) when is_binary(word) and is_binary(player_id) do
    GenServer.call(edge_name(game_id, player_id), {:submit_word, word})
  end

  @doc """
  Returns the `pid` of the game with the given `game_id`.
  """
  def whereis(game_id) do
    case Horde.Registry.lookup(DistributedRegistry, game_id) do
      [{pid, _}] when is_pid(pid) -> pid
      _ -> nil
    end
  end

  # defp game_name(game_id) when is_binary(game_id), do: DistributedRegistry.via_tuple(game_id)
  defp edge_name(game_id, player_id), do: EdgeServer.name(game_id, player_id)
end
