defmodule WeDle.Game.NodeListener do
  @moduledoc """
  Listens for `{:nodeup, node}` and `{:nodedown, node}` events and
  adjusts the members of the Horde clusters accordingly.

  Must be after the `WeDle.DistributedSupervisor` in the application
  supervision tree.
  """

  use GenServer

  alias WeDle.Game.DistributedRegistry

  # -- Client API --

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  # -- Callbacks --

  @impl true
  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(DistributedRegistry)
    {:noreply, state}
  end

  def handle_info({:nodedown, _node, _node_type}, state) do
    set_members(DistributedRegistry)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp set_members(name) do
    members =
      Node.list([:visible, :this])
      |> Enum.map(&{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
  end
end
