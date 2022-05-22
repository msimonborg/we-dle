defmodule WeDle.Game.Supervisor do
  @moduledoc """
  The `WeDle.Game.Supervisor` starts and supervises the
  game system. This includes the following child processes:

    * `WeDle.Game.Handoff.Supervisor` supervises processes responsible
    for game state handoff

    * `Wedle.Game.DistributedRegistry` to register and lookup
    `WeDle.Game.Server` processes across the cluster

    * `WeDle.Game.DistributedSupervisor` and to start and supervise
    `WeDle.Game.Server`s across the cluster

    * `WeDle.Game.NodeListener` to keep cluster membership up to date

    * `WeDle.Game.EdgeRegistry` to register local `WeDle.Game.EdgeServer`s

    * `WeDle.Game.EdgeSupervisor` to start and supervise
    `WeDle.Game.EdgeServer`s locally on the same node as the player

    * `WeDle.Game.ShutdownSignal` sends an early shutdown warning to
    interested processes
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
      {Task, fn -> Game.Handoff.set_neighbors() end},
      Game.DistributedRegistry,
      Game.NodeListener,
      Game.ServerSupervisor,
      {Registry, keys: :unique, name: Game.EdgeRegistry, partitions: System.schedulers_online()},
      Game.EdgeSupervisor,
      Game.ShutdownSignal
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
