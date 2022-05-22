defmodule WeDle.Game.EdgeSupervisor do
  @moduledoc """
  A `DynamicSupervisor` that starts and supervises
  `WeDle.Game.EdgeServer`s locally on the same node as the
  player.
  """

  use DynamicSupervisor

  alias WeDle.Game.{EdgeServer, Player}

  @partition_sup_name WeDle.Game.EdgeSupervisors

  # -- Client API --

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  @doc """
  Starts a new supervised `WeDle.Game.EdgeServer`.

  The new server will be registered under a name associated to the given
  `game_id` and `player_id`.
  """
  def start_edge(game_id, player_id) do
    DynamicSupervisor.start_child(
      rand_partition(),
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
  and `player_id`. If successful, this function returns `:ok`.
  If no server is found, this function returns `{:error, :not_found}`.
  """
  def terminate_edge(game_id, player_id) do
    game_id
    |> EdgeServer.name(player_id)
    |> GenServer.whereis()
    |> case do
      pid when is_pid(pid) -> GenServer.stop(pid)
      _ -> {:error, :not_found}
    end
  end

  defp rand_partition do
    partitions = PartitionSupervisor.partitions(@partition_sup_name)
    {:via, PartitionSupervisor, {@partition_sup_name, Enum.random(1..partitions)}}
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
