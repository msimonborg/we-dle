defmodule WeDle.Game do
  @moduledoc """
  The public API for starting and stopping games, and game logic.
  """

  require Logger

  alias WeDle.Game.{
    Board,
    DistributedRegistry,
    EdgeServer,
    Handoff,
    Player,
    Server
  }

  alias WeDle.Handoffs

  defstruct [:id, :word_length, :started_at, :winner, players: %{}, edge_servers: %{}]

  @type id :: String.t()
  @type option :: {:word_length, pos_integer}
  @type options :: [option]
  @type player :: Player.t()
  @type t :: %__MODULE__{
          id: id,
          word_length: pos_integer,
          started_at: DateTime.t(),
          players: %{id => player},
          edge_servers: %{
            id => %{
              ref: reference,
              pid: pid,
              pings: non_neg_integer,
              avg_latency: non_neg_integer
            }
          },
          winner: player | nil
        }

  @doc """
  Starts a new game.

  Returns `{:ok, pid}` on success, or `{:error, {:already_started, pid}}`
  if the game is already started.

  ## Options

    * `:word_length` - the word length for the challenge, defaults to 5

  ## Examples

      iex> {:ok, pid} = WeDle.Game.start("game")
      iex> WeDle.Game.join("game", "p1")
      iex> is_pid(pid)
      true

      iex> {:ok, pid} = WeDle.Game.start("other_game")
      iex> WeDle.Game.join("other_game", "p1")
      iex> {:error, {:already_started, ^pid}} = WeDle.Game.start("other_game")
  """
  @spec start(id) :: Server.on_start()
  def start(game_id, opts \\ []) do
    opts
    |> Keyword.put_new(:word_length, 5)
    |> Keyword.put(:game_id, game_id)
    |> do_start()
  end

  defp do_start(opts) do
    sup_name = {:via, PartitionSupervisor, {WeDle.Game.ServerSupervisors, self()}}
    DynamicSupervisor.start_child(sup_name, {Server, opts})
  end

  @doc """
  Joins a running game.

  Returns `{:ok, player}` where `player` is a `WeDle.Game.Player` struct representing
  the player that just joined, or `{:error, reason}`.

  When joining a game, a `WeDle.Game.EdgeServer` is spawned to provide the connection,
  forwarding messages and changes and state between client and server. If the game is
  stopped a message will be sent to the client's inbox in the form `{:game_down, reason}`.

  ## Examples

      iex> WeDle.Game.start("diva_game")
      iex> {:ok, %WeDle.Game.Player{id: "Madonna"}} = WeDle.Game.join("diva_game", "Madonna")
      iex> {:ok, %WeDle.Game.Player{id: "Tina"}} = WeDle.Game.join("diva_game", "Tina")
      iex> WeDle.Game.join("diva_game", "Sade")
      {:error, :player_not_found}

      iex> WeDle.Game.join("unjoinable_game", "Nobody")
      {:error, :game_not_found}
  """
  @spec join(id, id) :: {:ok, player} | {:error, term}
  def join(game_id, player_id) do
    case whereis(game_id) do
      pid when is_pid(pid) ->
        join(pid, game_id, player_id)

      _ ->
        {:error, :game_not_found}
    end
  end

  defp join(game_pid, game_id, player_id) do
    edge_pid =
      case EdgeServer.start_edge(game_pid, game_id, player_id) do
        {:ok, pid} when is_pid(pid) -> pid
        {:error, {:already_started, pid}} -> pid
      end

    GenServer.call(edge_pid, :join_game)
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
      {:error, {:already_started, pid}} -> join(pid, game_id, player_id)
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
      iex> Process.sleep(1) # Wait for messages to be processed
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
    game_id
    |> name()
    |> GenServer.whereis()
  end

  @doc """
  Returns the name for registration of the game with the given `game_id`.
  """
  def name(game_id) do
    DistributedRegistry.via_tuple(game_id)
  end

  @doc """
  Generates a unique game ID.

  ## Examples

      WeDle.Game.unique_id()
      # => "0095dda6-5eb3-4c1d-8437-f0b792fe82b1"
  """
  @spec unique_id :: String.t()
  def unique_id, do: Ecto.UUID.generate()

  @doc """
  Checks if the game exists as a running server or a stored handoff.

  ## Examples

      iex> WeDle.Game.start_or_join("existing", "p1")
      iex> WeDle.Game.exists?("existing")
      true

      iex> WeDle.Game.exists?("non-existing")
      false
  """
  @spec exists?(id) :: boolean
  def exists?(game_id) do
    !!(whereis(game_id) || Handoffs.get_handoff(game_id))
  end

  @doc """
  Forces a game to expire and bypass a handoff, blocking until
  `Process.alive?/1` returns `false`.

  This function guarantees that `exists?/1` will return false
  after it returns.

  ## Examples

      iex> WeDle.Game.start_or_join("expire", "p1")
      iex> WeDle.Game.force_expire("expire")
      :ok
      iex> WeDle.Game.exists?("expire")
      false
      iex> WeDle.Game.force_expire("expire")
      {:error, :game_not_found}
  """
  @spec force_expire(id) :: :ok
  def force_expire(game_id) do
    case whereis(game_id) do
      pid when is_pid(pid) ->
        send(pid, :expire)
        :ok = block_until_expired(pid)

      _ ->
        {:error, :game_not_found}
    end
  end

  defp block_until_expired(pid) do
    if Process.alive?(pid), do: block_until_expired(pid), else: :ok
  end

  @doc """
  Restarts the game, resetting to a fresh state.

  The expiration timer is also reset.

  Returns `:ok` if the game exists, otherwise
  `{:error, :game_not_found}`.

  ## Examples

      iex> {:ok, _} = WeDle.Game.start_or_join("reset", "p1")
      iex> WeDle.Game.reset("reset")
      :ok

      iex> WeDle.Game.reset("noreset")
      {:error, :game_not_found}
  """
  @spec reset(id) :: {:ok, t} | {:error, :game_not_found}
  def reset(game_id) do
    case whereis(game_id) do
      pid when is_pid(pid) ->
        :ok =
          game_id
          |> name()
          |> GenServer.call(:reset)

      _ ->
        {:error, :game_not_found}
    end
  end

  @doc """
  Returns a `Game` struct from a `Handoff` struct.
  """
  def game_from_handoff(%Handoff{} = handoff) do
    %__MODULE__{
      id: handoff.game_id,
      word_length: handoff.word_length,
      started_at: handoff.started_at,
      players: build_players_from_handoff(handoff)
    }
  end

  defp build_players_from_handoff(handoff) do
    %{}
    |> maybe_add_player1(handoff)
    |> maybe_add_player2(handoff)
  end

  defp maybe_add_player1(map, %{player1_id: id} = handoff) when not is_nil(id) do
    args = %{
      id: id,
      game_id: handoff.game_id,
      rows: handoff.player1_rows,
      word_length: handoff.word_length,
      player_challenge: handoff.player1_challenge,
      opponent_challenge: handoff.player2_challenge
    }

    build_player(map, args)
  end

  defp maybe_add_player1(map, _), do: map

  defp maybe_add_player2(map, %{player2_id: id} = handoff) when not is_nil(id) do
    args = %{
      id: id,
      game_id: handoff.game_id,
      rows: handoff.player2_rows,
      word_length: handoff.word_length,
      player_challenge: handoff.player2_challenge,
      opponent_challenge: handoff.player1_challenge
    }

    build_player(map, args)
  end

  defp maybe_add_player2(map, _), do: map

  defp build_player(map, args) do
    board =
      if args.opponent_challenge do
        words = String.split(args.rows, "\n") |> Enum.filter(&(&1 != ""))

        Enum.reduce(words, Board.new(args.word_length), fn word, board ->
          Board.insert(board, word, args.opponent_challenge)
        end)
      else
        Board.new(args.word_length)
      end

    Map.merge(map, %{
      args.id =>
        Player.new(
          id: args.id,
          game_id: args.game_id,
          board: board,
          challenge: args.player_challenge
        )
    })
  end

  defp edge_name(game_id, player_id), do: EdgeServer.name(game_id, player_id)
end
