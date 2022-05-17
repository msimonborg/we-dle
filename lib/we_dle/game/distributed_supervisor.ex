defmodule WeDle.Game.DistributedSupervisor do
  @moduledoc """
  Uses `Horde.Supervisor` to dynamically start and supervise long running
  processes evenly distributed across the cluster.

  Must be after the `WeDle.DistributedRegistry` and before the
  `WeDle.NodeListener` in the application supervision tree.
  """

  use Horde.DynamicSupervisor

  # -- Client API --

  def start_link(_) do
    opts = [strategy: :one_for_one, shutdown: 5_000]
    Horde.DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a child process under dynamic distributed supervision.

  If the child dies it will be restarted, potentially on another
  node in the cluster.
  """
  def start_child(child_spec) do
    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # -- Callbacks --

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  defp members do
    Node.list([:visible, :this])
    |> Enum.map(&{__MODULE__, &1})
  end
end
