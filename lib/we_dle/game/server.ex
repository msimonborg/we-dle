defmodule WeDle.Game.Server do
  @moduledoc """
  The `WeDle.Game.Server` holds the game state and publishes
  events to subscribers of that game.
  """

  use GenServer, shutdown: 10_000, restart: :transient

  require Logger

  alias WeDle.Game
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
    game_id = Keyword.fetch!(opts, :game_id)
    word_length = Keyword.fetch!(opts, :word_length)
    :timer.send_interval(10_000, :ping)
    {:ok, struct!(Game, id: game_id, word_length: word_length)}
  end

  @impl true
  def handle_call({:join_game, player_id}, {pid, _}, %{players: players} = game)
      when map_size(players) == 2 do
    with {:ok, player} <- get_player(game, player_id),
         {:ok, opponent} <- get_opponent(game, player_id) do
      do_join_game(game, player_id, player, opponent, pid)
    else
      {:error, _} = error -> {:reply, error, game}
    end
  end

  def handle_call({:join_game, player_id}, {pid, _}, %{players: players} = game)
      when map_size(players) < 2 do
    player =
      Map.get_lazy(players, player_id, fn ->
        board = Board.new(game.word_length)
        Player.new(id: player_id, game_id: game.id, board: board)
      end)

    opponent = send_update_to_opponent(game, player)
    do_join_game(game, player_id, player, opponent, pid)
  end

  @impl true
  def handle_info({:update_player, player}, %{players: players} = game) do
    send_update_to_opponent(game, player)
    {:noreply, %{game | players: Map.put(players, player.id, player)}}
  end

  def handle_info(:ping, %{edge_servers: edge_servers} = game) do
    Enum.each(edge_servers, fn {id, edge} ->
      send(edge.pid, {:ping, self(), id, :erlang.monotonic_time(:millisecond)})
    end)

    {:noreply, game}
  end

  def handle_info({:pong, id, time}, %{edge_servers: edge_servers} = game) do
    case Map.get(edge_servers, id) do
      nil ->
        {:noreply, game}

      %{} = edge ->
        pings = edge.pings + 1
        interval = :erlang.monotonic_time(:millisecond) - time
        avg_latency = (edge.pings * edge.avg_latency + interval) / pings
        edge = %{edge | pings: pings, avg_latency: avg_latency}
        {:noreply, %{game | edge_servers: Map.replace!(edge_servers, id, edge)}}
    end
  end

  def handle_info({:DOWN, ref, _, _, _}, %{edge_servers: edge_servers} = game) do
    Process.demonitor(ref, [:flush])
    {player_id, _} = Enum.find(edge_servers, fn {_, edge} -> edge.ref == ref end)
    {:noreply, %{game | edge_servers: Map.delete(edge_servers, player_id)}}
  end

  # -- Private Helpers --

  defp do_join_game(game, player_id, player, opponent, pid) do
    if edge = Map.get(game.edge_servers, player_id), do: Process.demonitor(edge.ref, [:flush])
    ref = Process.monitor(pid)
    new_edge = %{ref: ref, pid: pid, pings: 0, avg_latency: 0}
    edge_servers = Map.put(game.edge_servers, player_id, new_edge)
    players = Map.put_new(game.players, player_id, player)
    game = %{game | edge_servers: edge_servers, players: players}
    reply = %{player: player, opponent: opponent}
    {:reply, {:ok, reply}, game}
  end

  defp send_update_to_opponent(game, player) do
    opponent =
      case get_opponent(game, player.id) do
        {:ok, opponent} -> opponent
        {:error, _} -> nil
      end

    if opponent do
      pid = game.edge_servers[opponent.id].pid
      send(pid, {:update_opponent, player})
    end

    opponent
  end

  defp get_player(%{players: players} = game, player_id) do
    result = Map.get(players, player_id)

    if result do
      {:ok, result}
    else
      Logger.debug("""
      cannot find player with id #{player_id} in game:

          #{inspect(game)}
      """)

      {:error, :player_not_found}
    end
  end

  defp get_opponent(%{players: players} = game, player_id) do
    result = Enum.find(players, fn {id, _} -> id != player_id end)

    if result do
      {_, opponent} = result
      {:ok, opponent}
    else
      Logger.debug("""
      cannot find opponent of player with id #{player_id} in game:

          #{inspect(game)}
      """)

      {:error, :opponent_not_found}
    end
  end
end
