defmodule WeDle.Game.ServerSupervisor do
  @moduledoc """
  Uses `Horde.Supervisor` to dynamically start and supervise long running
  processes evenly distributed across the cluster.

  Must be after the `WeDle.DistributedRegistry` and before the
  `WeDle.NodeListener` in the application supervision tree.
  """

  use DynamicSupervisor

  @partition_sup_name WeDle.Game.ServerSupervisors

  # -- Client API --

  def start_link(_) do
    opts = [strategy: :one_for_one, shutdown: 60_000]
    DynamicSupervisor.start_link(__MODULE__, opts)
  end

  @doc """
  Starts a child process under dynamic distributed supervision.

  If the child dies it will be restarted, potentially on another
  node in the cluster.
  """
  def start_child(child_spec) do
    DynamicSupervisor.start_child(rand_partition(), child_spec)
  end

  defp rand_partition do
    partitions = PartitionSupervisor.partitions(@partition_sup_name)
    {:via, PartitionSupervisor, {@partition_sup_name, Enum.random(1..partitions)}}
  end

  # -- Callbacks --

  @impl true
  def init(opts) do
    DynamicSupervisor.init(opts)
  end
end
