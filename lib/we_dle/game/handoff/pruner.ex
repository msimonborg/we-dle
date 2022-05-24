defmodule WeDle.Game.Handoff.Pruner do
  @moduledoc """
  The `WeDle.Game.Handoff.Pruner` keeps all game ids with handoff state
  in an ETS table, and periodically scans the table for old processes
  that can be pruned from the handoff map.
  """

  use GenServer

  require Logger

  alias WeDle.Handoffs

  defstruct node_status: :alive

  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

  # Prune every ten minutes
  @pruning_interval 10

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    send(self(), :prune)

    @pruning_interval
    |> to_millisecond()
    |> :timer.send_interval(:prune)

    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(:prune, %{node_status: :shutting_down} = state), do: {:noreply, state}

  def handle_info(:prune, state) do
    Logger.info("#{__MODULE__} deleting handoffs older than #{@pruning_interval} minute(s)")

    @pruning_interval
    |> to_millisecond()
    |> Handoffs.delete_handoffs_older_than(:millisecond)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:shutting_down, state) do
    {:noreply, %{state | node_status: :shutting_down}}
  end

  defp to_millisecond(minutes), do: minutes * 60_000
end
