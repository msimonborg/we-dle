defmodule WeDle.Game.ServerSupervisor do
  @moduledoc """
  Uses `Horde.Supervisor` to dynamically start and supervise long running
  processes evenly distributed across the cluster.

  Must be after the `WeDle.DistributedRegistry` and before the
  `WeDle.NodeListener` in the application supervision tree.
  """

  use DynamicSupervisor

  # -- Client API --

  def start_link(_) do
    opts = [strategy: :one_for_one, shutdown: 60_000]
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a child process under dynamic distributed supervision.

  If the child dies it will be restarted, potentially on another
  node in the cluster.
  """
  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # -- Callbacks --

  @impl true
  def init(opts) do
    DynamicSupervisor.init(opts)
  end
end
