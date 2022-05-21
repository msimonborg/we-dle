defmodule WeDle.Game.EdgeServer do
  @moduledoc """
  The `WeDle.Game.EdgeServer` is a process that runs locally
  on the same node as the player, providing fast computation
  and an interface to the `WeDle.Game.Server`.
  """

  use GenServer, restart: :transient

  require Logger

  alias WeDle.Game

  alias WeDle.Game.{
    Board,
    DistributedRegistry,
    EdgeRegistry,
    Player
  }

  defstruct [
    :player_id,
    :player,
    :opponent,
    :game_id,
    :game_name,
    :game_pid,
    :game_monitor,
    :client_pid,
    :client_monitor
  ]

  @type game_name :: {:via, Horde.Registry, {DistributedRegistry, String.t()}}
  @type name :: {:via, Registry, {EdgeRegistry, String.t()}}
  @type player :: Player.t()
  @type t :: %__MODULE__{
          player_id: String.t(),
          player: player,
          opponent: player,
          game_id: String.t(),
          game_name: game_name,
          game_pid: pid,
          game_monitor: reference,
          client_pid: pid,
          client_monitor: reference
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

  def join_game(pid, game_id, player_id) do
    game_id
    |> name(player_id)
    |> GenServer.call({:join_game, pid})
  end

  # -- Callbacks --

  @impl true
  def init({game_id, player_id, client_pid}) do
    game_name = game_name(game_id)
    game_pid = GenServer.whereis(game_name)
    game_monitor = Process.monitor(game_pid)
    client_monitor = Process.monitor(client_pid)

    {:ok,
     struct!(__MODULE__,
       game_name: game_name,
       game_id: game_id,
       game_pid: game_pid,
       game_monitor: game_monitor,
       player_id: player_id,
       client_pid: client_pid,
       client_monitor: client_monitor
     )}
  end

  @impl true
  def handle_call({:join_game, game_pid}, {client_pid, _} = from, %{client_pid: nil} = state) do
    handle_call({:join_game, game_pid}, from, %{state | client_pid: client_pid})
  end

  def handle_call({:join_game, game_pid}, _, %{player_id: player_id} = state) do
    case GenServer.call(game_pid, {:join_game, player_id}) do
      {:ok, %{player: player, opponent: opponent}} ->
        {:reply, {:ok, player}, %{state | player: player, opponent: opponent}}

      {:error, _} = error ->
        {:stop, :normal, error, state}
    end
  end

  def handle_call({:set_challenge, word}, _, %{player: player, game_id: game_id} = state) do
    case ensure_challenge_not_set(player, word) do
      :ok ->
        player = %{player | challenge: word}
        send_player_update_to_game(game_id, player)
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
      send_player_update_to_game(state.game_id, player)
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
        {:DOWN, ref, _, _, reason},
        %{game_monitor: game_monitor, client_monitor: client_monitor} = state
      ) do
    Process.demonitor(ref, [:flush])

    case ref do
      ^game_monitor ->
        pid = state.client_pid
        if pid && Process.alive?(pid), do: send(pid, {:game_down, reason})
        {:stop, reason, %{state | game_pid: nil, game_monitor: nil}}

      ^client_monitor ->
        {:noreply, %{state | client_pid: nil, client_monitor: nil}}
    end
  end

  # -- Private Helpers --

  defp game_name(game_id) do
    DistributedRegistry.via_tuple(game_id)
  end

  defp send_player_update_to_game(game_id, player) do
    name = Game.name(game_id)

    with pid when is_pid(pid) <- GenServer.whereis(name) do
      send(pid, {:update_player, player})
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
