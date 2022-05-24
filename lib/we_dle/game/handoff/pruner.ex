defmodule WeDle.Game.Handoff.Pruner do
  # Prune every ten minutes
  @pruning_interval 10

  @moduledoc """
  The `WeDle.Game.Handoff.Pruner` periodically deletes all
  handoffs in the database that are more than #{@pruning_interval}
  minute(s) old.
  """

  use GenServer

  require Logger

  alias WeDle.Handoffs

  defstruct node_status: :alive

  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

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
  def handle_info(:shutting_down, state), do: {:noreply, %{state | node_status: :shutting_down}}

  def handle_info(:prune, state) do
    Logger.info("#{__MODULE__} deleting handoffs older than #{@pruning_interval} minute(s)")

    @pruning_interval
    |> to_millisecond()
    |> Handoffs.delete_handoffs_older_than(:millisecond)

    {:noreply, state}
  end

  defp to_millisecond(minutes), do: minutes * 60_000
end
