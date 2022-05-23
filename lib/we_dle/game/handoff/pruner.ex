defmodule WeDle.Game.Handoff.Pruner do
  @moduledoc """
  The `WeDle.Game.Handoff.Pruner` keeps all game ids with handoff state
  in an ETS table, and periodically scans the table for old processes
  that can be pruned from the handoff map.
  """

  use GenServer

  alias WeDle.Handoffs

  defstruct node_status: :alive

  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

  # Prune every ten minutes
  @pruning_interval 1_000 * 60 * 10

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    :timer.send_interval(@pruning_interval, :prune)
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(:prune, %{node_status: :shutting_down} = state), do: {:noreply, state}

  def handle_info(:prune, state) do
    Handoffs.delete_stale_handoffs(@pruning_interval, :millisecond)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:shutting_down, state) do
    {:noreply, %{state | node_status: :shutting_down}}
  end
end
