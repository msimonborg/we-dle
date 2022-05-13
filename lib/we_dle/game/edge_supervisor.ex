defmodule WeDle.Game.EdgeSupervisor do
  @moduledoc """
  A `DynamicSupervisor` that starts and supervises
  `WeDle.Game.EdgeServer`s locally on the same node as the
  player.
  """

  use DynamicSupervisor

  alias WeDle.Game.{EdgeServer, Player}

  # -- Client API --

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a new supervised `WeDle.Game.EdgeServer`.

  The new server will be registered under a name associated to the given
  `game_id` and `player_id`.
  """
  def start_edge(game_id, player_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {EdgeServer, game_id: game_id, player_id: player_id, client_pid: self()}
    )
  end

  @doc """
  Stops the `WeDle.Game.EdgeServer` identified by the given `player`.
  """
  def terminate_edge(%Player{} = player) do
    terminate_edge(player.game_id, player.id)
  end

  @doc """
  Stops the `WeDle.Game.EdgeServer` identified by the given `game_id`
  and `player_id`.
  """
  def terminate_edge(game_id, player_id) do
    pid =
      game_id
      |> EdgeServer.name(player_id)
      |> GenServer.whereis()

    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
