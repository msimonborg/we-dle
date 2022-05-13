defmodule WeDle.Game.EdgeServer do
  @moduledoc """
  The `WeDle.Game.EdgeServer` is a process that runs locally
  on the same node as the player, providing fast computation
  and an interface to the `WeDle.Game.Server`.
  """

  use GenServer

  require Logger

  alias WeDle.Game.{
    Board,
    DistributedRegistry,
    EdgeRegistry,
    Player
  }

  defstruct [:player, :opponent, :game_id, :game_name, :client_pid]

  @type game_name :: {:via, Horde.Registry, {DistributedRegistry, String.t()}}
  @type name :: {:via, Registry, {EdgeRegistry, String.t()}}
  @type option :: {:game_id | :player_id, String.t()}
  @type options :: [option]
  @type player :: Player.t()
  @type t :: %__MODULE__{
          player: player,
          opponent: player,
          game_id: String.t(),
          game_name: game_name,
          client_pid: pid
        }

  # -- Client API --

  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    player_id = Keyword.fetch!(opts, :player_id)
    client_pid = Keyword.fetch!(opts, :client_pid)

    GenServer.start_link(__MODULE__, {game_id, player_id, client_pid},
      name: name(game_id, player_id)
    )
  end

  @doc """
  Returns a `:via` tuple to register and lookup `WeDle.Game.EdgeServer`
  processes on the local node.

  `player` is the `%WeDle.Game.Player` struct associated to the server.
  """
  @spec name(player) :: name
  def name(%Player{} = player) do
    name(player.game_id, player.id)
  end

  @doc """
  Returns a `:via` tuple to register and lookup `WeDle.Game.EdgeServer`
  processes on the local node.
  """
  @spec name(String.t(), String.t()) :: name
  def name(game_id, player_id) do
    {:via, Registry, {EdgeRegistry, "#{player_id}@#{game_id}"}}
  end

  def join_game(game_id, player_id) do
    game_id
    |> name(player_id)
    |> GenServer.call({:join_game, game_id, player_id})
  end

  # -- Callbacks --

  @impl true
  def init({_, _, client_pid} = init_arg) do
    Process.monitor(client_pid)
    {:ok, init_arg, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, {game_id, player_id, client_pid}) do
    game_name = game_name(game_id)
    %{player: player, opponent: opponent} = GenServer.call(game_name, {:connect_edge, player_id})

    {:noreply,
     struct!(__MODULE__,
       game_name: game_name,
       game_id: game_id,
       player: player,
       opponent: opponent,
       client_pid: client_pid
     )}
  end

  @impl true
  def handle_call({:set_challenge, word}, _, %{player: player, game_name: game_name} = state) do
    case ensure_challenge_not_set(player, word) do
      :ok ->
        player = Map.put(player, :challenge, word)
        GenServer.cast(game_name, {:update_player, player})
        {:reply, {:ok, player}, %{state | player: player}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:submit_word, _}, _, %{opponent: nil} = state) do
    {:reply, {:error, :opponent_not_found}, state}
  end

  def handle_call({:submit_word, word}, _, %{player: player, opponent: opponent} = state) do
    with :ok <- ensure_challenge_is_set(opponent),
         %Board{} = board <- Board.insert(player.board, word, opponent.challenge) do
      player = %{player | board: board}
      {:reply, {:ok, player}, %{state | player: player}}
    else
      {:error, _} = error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _}, state) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | client_pid: nil}}
  end

  # -- Private Helpers --

  defp game_name(game_id) do
    DistributedRegistry.via_tuple(game_id)
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
      player = Player.new(id: player_id, game_id: game.id, board: board)
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

  def handle_call({:connect_edge, player_id}, {pid, _}, game) do
    case get_player(game, player_id) do
      {:ok, {index, %Player{} = player}} ->
        ref = Process.monitor(pid)
        game = update_in(game.edge_servers, &Map.put(&1, ref, %{player: index, pid: pid}))

        opponent =
          case get_opponent(game, player_id) do
            {:ok, {_, %Player{} = player}} -> player
            {:error, _} -> nil
          end

        {:reply, %{player: player, opponent: opponent}, game}

      {:error, _} = error ->
        {:reply, error, game}
    end
  end

  @impl true
  def handle_cast({:update_player, %{id: id} = player}, %{edge_servers: edge_servers} = game) do
    {:ok, {index, %Player{}}} = get_player(game, id)

    opponent_edge =
      Enum.find(edge_servers, fn {_, %{player: i}} ->
        i != index
      end)

    GenServer.cast(opponent_edge.pid, {:update_opponent, player})
    {:noreply, put_in(game.players[index], player)}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _}, game) do
    Process.demonitor(ref, [:flush])
    {:noreply, update_in(game.edge_servers, &Map.delete(&1, ref))}
  end

  # -- Private Helpers --

  defp build_state(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    word_length = Keyword.fetch!(opts, :word_length)
    struct!(Game, id: game_id, word_length: word_length)
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
end
