defmodule WeDle.Game.PlayerCounter do
  @moduledoc """
  A GenServer that communicates with other clustered nodes to
  provide an eventually consistent global count of connected players.

  Uses the count of `EdgeServer` pids in each local `EdgeRegistry`
  to represent the number of players connected to the local node.
  Local counts are broadcast to all other nodes in the cluster,
  and updates to node membership are subscribed to with
  `:net_kernel.monitor_nodes/2`. The global count is considered to
  be the local count plus the counts from all other active nodes.

  The global count is aggregated every 5 seconds and broadcast on the
  `"player_count"` pubsub topic. This topic can be joined with
  `subscribe/0`. The count is also stored in an ETS table to provide
  fast concurrent access on demand through the `get/0` function.
  """

  use GenServer

  alias WeDle.Game.EdgeRegistry

  @enforce_keys [:global_count, :node_counts]
  defstruct [:global_count, :node_counts]

  @type t :: %__MODULE__{global_count: non_neg_integer, node_counts: %{atom => non_neg_integer}}

  @ets_name __MODULE__
  @interval :timer.seconds(5)
  @pubsub WeDle.PubSub
  @topic "player_counter"

  # -- Client API --

  @doc false
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Get the current global player count.

  Counts are eventually consistent and updated on a sync interval of
  five seconds. The value is read from an ETS table with read
  concurrency enabled.
  """
  @spec get :: non_neg_integer
  def get do
    :ets.lookup_element(@ets_name, :global_count, 2)
  end

  @doc """
  Subscribe to the `"player_counter"` pubsub topic to receive an
  update broadcast every five seconds.

  Broadcast messages are in the shape of
  `{"player_counter", count :: non_neg_integer}`.
  """
  @spec subscribe :: :ok | {:error, term}
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    :net_kernel.monitor_nodes(true)

    :ets.new(@ets_name, [:named_table, :protected, read_concurrency: true])
    :ets.insert(@ets_name, {:global_count, 0})

    :timer.send_interval(@interval, :aggregate)

    node_counts = for node <- Node.list(), into: %{}, do: {node, 0}
    {:ok, struct!(__MODULE__, global_count: 0, node_counts: node_counts)}
  end

  @impl true
  def handle_info({:nodeup, node}, %{node_counts: node_counts} = state) do
    {:noreply, %{state | node_counts: Map.put_new(node_counts, node, 0)}}
  end

  def handle_info({:nodedown, node}, %{node_counts: node_counts} = state) do
    {:noreply, %{state | node_counts: Map.delete(node_counts, node)}}
  end

  def handle_info({:count, node, count}, %{node_counts: node_counts} = state) do
    {:noreply, %{state | node_counts: Map.put(node_counts, node, count)}}
  end

  def handle_info(:aggregate, %{global_count: global_count, node_counts: node_counts} = state) do
    local_count = Registry.count(EdgeRegistry)

    new_global_count =
      Enum.reduce(node_counts, local_count, fn {_, node_count}, acc -> acc + node_count end)

    for {node, _} <- node_counts, do: send({__MODULE__, node}, {:count, Node.self(), local_count})

    unless new_global_count == global_count do
      :ets.insert(@ets_name, {:global_count, new_global_count})
      Phoenix.PubSub.local_broadcast(@pubsub, @topic, {@topic, new_global_count})
    end

    {:noreply, %{state | global_count: new_global_count}}
  end
end
