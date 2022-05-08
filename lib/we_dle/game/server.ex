defmodule WeDle.Game.Server do
  @moduledoc """
  The `WeDle.Game.Server` holds the game state and publishes
  events to subscribers of that game.
  """

  use GenServer, shutdown: 10_000, restart: :transient

  require Logger

  alias WeDle.{Game, GameError}
  alias Game.{Board, DistributedRegistry, Player}

  @type on_start :: {:ok, pid} | :ignore | {:error, {ArgumentError, stacktrace :: list}}

  # -- Client API --

  @doc """
  Starts and links a new game server.

  Normally this will be done indirectly by passing the child
  spec to a supervisor, such as the `WeDle.Game.DistributedSupervisor`,
  or by calling the functions `WeDle.Game.start/1` or
  `WeDle.Game.start_or_join/3`.
  """
  @spec start_link(keyword) :: on_start
  def start_link(opts) when is_list(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    case GenServer.start_link(__MODULE__, opts, name: via_tuple(game_id)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  defp via_tuple(game_id), do: DistributedRegistry.via_tuple(game_id)

  # -- Callbacks --

  @impl true
  def init(opts) do
    {:ok, build_state(opts)}
  end

  defp build_state(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    word_length = Keyword.fetch!(opts, :word_length)
    struct!(Game, id: game_id, word_length: word_length)
  end

  @impl true
  def handle_call({:join_game, player_id}, _, %{players: players} = game)
      when map_size(players) < 2 do
    if Enum.any?(players, fn {_, p} -> p.id == player_id end) do
      Logger.warn("""
      player(id: #{player_id}) tried to join game(id: #{game.id}), but player
      has already joined
      """)

      {:reply, {:error, :player_already_joined}, game}
    else
      board = Board.new(game.word_length)
      player = Player.new(id: player_id, board: board)
      {:reply, {:ok, player}, add_player(game, player)}
    end
  end

  def handle_call({:join_game, player_id}, _, %{players: players} = game)
      when map_size(players) >= 2 do
    Logger.warn("""
    player(id: #{player_id}) tried to join game(id: #{game.id}), but game is full
    """)

    {:reply, {:error, :game_full}, game}
  end

  def handle_call({:set_challenge, word, player_id}, _, %{players: players} = game) do
    with {:ok, {index, player}} <- get_player(game, player_id),
         :ok <- ensure_challenge_not_set(player, word) do
      player = Map.put(player, :challenge, word)
      {:reply, {:ok, player}, %{game | players: Map.put(players, index, player)}}
    else
      {:error, _} = error -> {:reply, error, game}
    end
  end

  def handle_call({:submit_word, word, player_id}, _, %{winner: nil, players: players} = game) do
    with {:ok, {index, player}} <- get_player(game, player_id),
         {:ok, {_, opponent}} <- get_opponent(game, player_id),
         :ok <- ensure_challenge_is_set(opponent),
         %Board{} = board <- Board.insert(player.board, word, opponent.challenge) do
      player = %{player | board: board}
      players = %{players | index => player}
      {:reply, {:ok, player}, %{game | players: players}}
    else
      {:error, _} = error -> {:reply, error, game}
    end
  end

  defp add_player(%{players: players} = game, player) do
    index = map_size(players) + 1

    if Map.has_key?(players, index) do
      message = """
      did not expect to already have a player at index #{index} in game:

          #{inspect(game)}
      """

      Logger.error(message)
      raise GameError, message
    end

    %{game | players: Map.put(players, index, player)}
  end

  defp get_player(%{players: players} = game, player_id) do
    result = Enum.find(players, fn {_, p} -> p.id == player_id end)

    if result do
      {:ok, result}
    else
      Logger.warn("""
      cannot find player with id #{player_id} in game:

          #{inspect(game)}
      """)

      {:error, :player_not_found}
    end
  end

  defp get_opponent(%{players: players} = game, player_id) do
    result = Enum.find(players, fn {_, p} -> p.id != player_id end)

    if result do
      {:ok, result}
    else
      Logger.warn("""
      cannot find opponent of player with id #{player_id} in game:

          #{inspect(game)}
      """)

      {:error, :opponent_not_found}
    end
  end

  defp ensure_challenge_not_set(player, word) do
    if player.challenge do
      Logger.warn("""
      attempted to set challenge `"#{word}"`, but a challenge already exists for player:

          #{inspect(player)}
      """)

      {:error, :challenge_already_exists}
    else
      :ok
    end
  end

  defp ensure_challenge_is_set(player) do
    if player.challenge do
      :ok
    else
      Logger.warn("""
      attempted to access challenge from player(id: #{player.id}), but a
      challenge is not set for player:

          #{inspect(player)}
      """)

      {:error, :challenge_not_found}
    end
  end
end
