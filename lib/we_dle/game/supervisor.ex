defmodule WeDle.Game.Supervisor do
  @moduledoc """
  The `WeDle.Game.Supervisor` starts and supervises the
  game system. This includes the following child processes:

    * `WeDle.Game.Handoff.Supervisor` supervises processes responsible
    for game state handoff

    * `Wedle.Game.DistributedRegistry` registers and provides lookup for
    `WeDle.Game.Server` processes across the cluster

    * `WeDle.Game.NodeListener` keeps cluster membership up to date for
    the `WeDle.Game.DistributedRegistry`

    * `WeDle.Game.ServerSupervisors`, a `PartitionSupervisor` that pools
    `WeDle.Game.ServerSupervisor`s to supervise game processes

    * `WeDle.Game.EdgeRegistry` registers local `WeDle.Game.EdgeServer`s

    * `WeDle.Game.EdgeSupervisors`, a `PartitionSupervisor` that pools
    `WeDle.Game.EdgeSupervisor`s to start and supervise
    `WeDle.Game.EdgeServer`s locally on the same node as the player

    * `WeDle.Game.PlayerCounter` aggregates and broadcasts cluster-wide
    player counts

    * `WeDle.Game.ShutdownSignal` sends an early shutdown warning to
    subscribing processes
  """

  use Supervisor

  alias WeDle.Game

  # -- Client API --

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    children = [
      Game.Handoff.Supervisor,
      Game.DistributedRegistry,
      Game.NodeListener,
      {PartitionSupervisor, child_spec: server_sup_spec(), name: Game.ServerSupervisors},
      {Registry, keys: :unique, name: Game.EdgeRegistry, partitions: System.schedulers_online()},
      {PartitionSupervisor, child_spec: edge_sup_spec(), name: Game.EdgeSupervisors},
      Game.PlayerCounter,
      {Game.ShutdownSignal, subscribers: shutdown_subscribers()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp shutdown_subscribers do
    [
      Game.Handoff.NotificationStore,
      Game.Handoff.Listener,
      Game.Handoff.Pruner
    ]
  end

  defp server_sup_spec do
    {DynamicSupervisor, strategy: :one_for_one, shutdown: 60_000}
  end

  defp edge_sup_spec do
    {DynamicSupervisor, strategy: :one_for_one}
  end
end
