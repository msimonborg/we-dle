defmodule WeDle.Game.Server do
  @moduledoc """
  The `WeDle.Game.Server` holds the game state and publishes
  events to subscribers of that game.
  """

  use GenServer, shutdown: 10_000, restart: :transient

  require Logger

  alias WeDle.{
    Game,
    Game.Board,
    Game.DistributedRegistry,
    Game.Handoff,
    Game.Player,
    Handoffs
  }

  alias WeDle.Game.Handoff.Registry, as: HandoffRegistry

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
    Process.flag(:trap_exit, true)
    :timer.send_interval(60_000, :ping_edge_servers)

    game_id = Keyword.fetch!(opts, :game_id)
    word_length = Keyword.fetch!(opts, :word_length)

    # Register for handoff before checking the database, to
    # avoid a possible race condition with the Handoff.Listener
    register_for_handoff(game_id)

    game = %Game{id: game_id, word_length: word_length, started_at: DateTime.utc_now()}

    {:ok, game, {:continue, :load_game}}
  end

  @impl true
  def handle_continue(:load_game, %{id: id} = game) do
    game =
      case Handoffs.get_handoff(id) do
        nil ->
          Process.send_after(self(), :unregister_for_handoff, 120_000)
          game

        handoff ->
          unregister_for_handoff(id)

          handoff
          |> Handoffs.delete_handoff!()
          |> Game.game_from_handoff()
      end

    {:noreply, set_expiration(game)}
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

  def handle_call(:reset, _, game) do
    {:stop, :reset, :ok, reset(game)}
  end

  defp reset(%{id: game_id, word_length: word_length}) do
    %Game{id: game_id, word_length: word_length, started_at: DateTime.utc_now()}
  end

  @impl true
  def handle_info(:expire, game) do
    {:stop, {:shutdown, :expired}, game}
  end

  def handle_info(:handoff_available, %{id: id} = _stale_game) do
    unregister_for_handoff(id)

    {:noreply,
     id
     |> Handoffs.get_handoff()
     |> Handoffs.delete_handoff!()
     |> Game.game_from_handoff()
     |> set_expiration()}
  end

  def handle_info(:unregister_for_handoff, game) do
    unregister_for_handoff(game.id)
    {:noreply, game}
  end

  def handle_info({:update_player, player}, %{players: players} = game) do
    send_update_to_opponent(game, player)
    {:noreply, %{game | players: Map.put(players, player.id, player)}}
  end

  def handle_info(:ping_edge_servers, %{edge_servers: edge_servers} = game) do
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

  def handle_info({:DOWN, ref, _, _, _}, %{edge_servers: edge_servers} = game)
      when map_size(edge_servers) <= 1 do
    {:noreply, demonitor_edge(ref, game), _timeout = 10_000}
  end

  def handle_info({:DOWN, ref, _, _, _}, game) do
    {:noreply, demonitor_edge(ref, game)}
  end

  def handle_info(:timeout, game) do
    {:stop, {:shutdown, :timeout}, game}
  end

  def handle_info({:EXIT, _, reason}, game) do
    Logger.debug("""
    game with ID "#{game.id}" exiting with reason: #{inspect(reason)}
    """)

    {:stop, reason, game}
  end

  def handle_info(message, game) do
    Logger.debug("""
    game #{game.id} received unexpected message in `handle_info`:

        #{inspect(message)}
    """)

    {:noreply, game}
  end

  defp demonitor_edge(ref, %{edge_servers: edge_servers} = game) do
    Process.demonitor(ref, [:flush])

    case Enum.find(edge_servers, fn {_, edge} -> edge.ref == ref end) do
      {player_id, _} -> %{game | edge_servers: Map.delete(edge_servers, player_id)}
      nil -> game
    end
  end

  @impl true

  def terminate(:reset, game) do
    Logger.debug("game with ID: \"#{game.id}\" resetting")
    :ok
  end

  def terminate({:shutdown, :expired}, game) do
    Logger.debug("game with ID: \"#{game.id}\" expiring")
    :ok
  end

  def terminate({:shutdown, :timeout}, game) do
    Logger.debug("game with ID: \"#{game.id}\" timed out with no connected players")
    terminate(:shutdown, game)
  end

  def terminate(_, game) do
    case Handoffs.create_handoff(game) do
      {:ok, %Handoff{}} ->
        Logger.debug("handoff created for game with ID: \"#{game.id}\"")
        :ok

      {:error, changeset} ->
        errors = for {field, {msg, _}} <- changeset.errors, do: "#{field} #{msg}"

        Logger.warn("""
        creating handoff for game(ID: "#{game.id}") failed with errors: #{inspect(errors)}
        attempting to delete old handoff and try once more to create a new one
        """)

        if Handoffs.delete_handoff_if_exists(game.id),
          do: Handoffs.create_handoff(game)

        :ok
    end
  end

  # -- Private Helpers --

  defp set_expiration(game) do
    expiration_time = expiration_time(game)

    if expiration_time > 0, do: Process.send_after(self(), :expire, expiration_time)
    game
  end

  defp expiration_time(game) do
    start_diff = DateTime.diff(DateTime.utc_now(), game.started_at, :millisecond)
    Handoff.expiration_time(:millisecond) - start_diff
  end

  defp do_join_game(game, player_id, player, opponent, pid) do
    edge = Map.get(game.edge_servers, player_id)

    if edge && edge.pid != pid do
      Process.demonitor(edge.ref, [:flush])
      Process.exit(edge.pid, :shutdown)
    end

    ref = Process.monitor(pid)
    new_edge = %{ref: ref, pid: pid, pings: 0, avg_latency: 0}

    edge_servers = Map.put(game.edge_servers, player_id, new_edge)
    players = Map.put_new(game.players, player_id, player)
    game = %{game | edge_servers: edge_servers, players: players}

    send(self(), :ping_edge_servers)

    reply = %{player: player, opponent: opponent}
    {:reply, {:ok, reply}, game}
  end

  defp send_update_to_opponent(game, player) do
    with {:ok, opponent} <- get_opponent(game, player.id),
         {:ok, opponent_edge} <- Map.fetch(game.edge_servers, opponent.id),
         {:ok, pid} <- Map.fetch(opponent_edge, :pid) do
      send(pid, {:update_opponent, player})
      opponent
    else
      _ -> nil
    end
  end

  defp register_for_handoff(game_id) do
    Registry.register(HandoffRegistry, game_id, [])
  end

  defp unregister_for_handoff(game_id) do
    Registry.unregister(HandoffRegistry, game_id)
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
