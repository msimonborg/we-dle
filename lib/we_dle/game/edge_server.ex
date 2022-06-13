defmodule WeDle.Game.EdgeServer do
  @moduledoc """
  The `WeDle.Game.EdgeServer` is a process that runs locally
  on the same node as the player, providing fast computation
  and an interface to the `WeDle.Game.Server`.
  """

  use GenServer, restart: :transient

  require Logger

  alias WeDle.Game.{
    Board,
    EdgeRegistry,
    Player
  }

  defstruct [
    :player_id,
    :player,
    :opponent,
    :game_id,
    :game_pid,
    :game_monitor,
    clients: %{}
  ]

  @type name :: {:via, Registry, {EdgeRegistry, String.t()}}
  @type player :: Player.t()
  @type t :: %__MODULE__{
          player_id: String.t(),
          player: player,
          opponent: player,
          game_id: String.t(),
          game_pid: pid,
          game_monitor: reference,
          clients: %{pid => reference}
        }

  # -- Client API --

  @doc false
  def start_link(opts) do
    name = name(opts[:game_id], opts[:player_id])
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Starts a new supervised edge server.

  The new server will be registered under a name associated to the given
  `game_id` and `player_id`.
  """
  def start_edge(game_pid, game_id, player_id)
      when is_pid(game_pid) and is_binary(game_id) and is_binary(player_id) do
    opts = [game_pid: game_pid, game_id: game_id, player_id: player_id, client_pid: self()]
    sup_name = {:via, PartitionSupervisor, {WeDle.Game.EdgeSupervisors, self()}}

    DynamicSupervisor.start_child(sup_name, {__MODULE__, opts})
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
  def name(game_id, player_id) when is_binary(game_id) and is_binary(player_id) do
    {:via, Registry, {EdgeRegistry, id(game_id, player_id)}}
  end

  defp id(game_id, player_id), do: "#{player_id}@#{game_id}"

  @doc """
  Returns the `pid` of the edge server for the given `player`.

  Returns `nil` if a process can't be found.
  """
  @spec whereis(player) :: pid | nil
  def whereis(%Player{} = player) do
    player
    |> name()
    |> GenServer.whereis()
  end

  @doc """
  Returns the `pid` of the edge server for the given `game_id`
  and `player_id`.

  Returns `nil` if a process can't be found.
  """
  @spec whereis(String.t(), String.t()) :: pid | nil
  def whereis(game_id, player_id) do
    game_id
    |> name(player_id)
    |> GenServer.whereis()
  end

  # -- Callbacks --

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    game_pid = Keyword.fetch!(opts, :game_pid)
    game_id = Keyword.fetch!(opts, :game_id)
    player_id = Keyword.fetch!(opts, :player_id)
    client_pid = Keyword.fetch!(opts, :client_pid)

    {:ok,
     struct!(__MODULE__,
       game_id: game_id,
       game_pid: game_pid,
       game_monitor: Process.monitor(game_pid),
       player_id: player_id,
       clients: %{client_pid => Process.monitor(client_pid)}
     )}
  end

  @impl true
  def handle_call(:join_game, {client_pid, _}, state) do
    %{player_id: player_id, game_pid: game_pid, clients: clients} = state

    case GenServer.call(game_pid, {:join_game, player_id}) do
      {:ok, %{player: player, opponent: opponent}} ->
        clients = Map.put_new_lazy(clients, client_pid, fn -> Process.monitor(client_pid) end)

        state = %{state | player: player, opponent: opponent, clients: clients}
        {:reply, {:ok, player}, state}

      {:error, _} = error ->
        {:stop, {:shutdown, error}, error, state}
    end
  end

  def handle_call({:set_challenge, word}, _, %{player: player, game_pid: game_pid} = state) do
    case ensure_challenge_not_set(player, word) do
      :ok ->
        player = %{player | challenge: word}
        send_player_update_to_game(game_pid, player)
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
      send_player_update_to_game(state.game_pid, player)

      {:reply, {:ok, player}, %{state | player: player}}
    else
      {:error, _} = error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_info({:update_opponent, opponent}, state) do
    {:noreply, %{state | opponent: opponent}}
  end

  def handle_info({:ping, server, id, time}, state) do
    send(server, {:pong, id, time})
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, ref, _, pid, reason},
        %{game_monitor: game_monitor, clients: clients} = state
      ) do
    Process.demonitor(ref, [:flush])

    case ref do
      ^game_monitor ->
        message = {:game_down, reason}
        for {pid, _} <- clients, do: send(pid, message)
        {:stop, {:shutdown, message}, %{state | game_pid: nil, game_monitor: nil}}

      _ ->
        clients = Map.delete(clients, pid)
        state = %{state | clients: clients}

        if map_size(clients) == 0,
          do: {:stop, {:shutdown, :no_clients}, state},
          else: {:noreply, state}
    end
  end

  @impl true
  def terminate({:shutdown, {:error, reason}}, state) do
    Logger.error(shutdown_log_message(state, reason))
  end

  def terminate({:shutdown, reason}, state) do
    Logger.debug(shutdown_log_message(state, reason))
  end

  defp shutdown_log_message(state, reason) do
    """
    edge server with ID "#{id(state.game_id, state.player_id)}" shutting down with reason: #{inspect(reason)}
    """
  end

  # -- Private Helpers --

  defp send_player_update_to_game(game_pid, player) do
    send(game_pid, {:update_player, player})
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
end
