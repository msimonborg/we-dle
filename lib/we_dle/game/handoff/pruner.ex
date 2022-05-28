defmodule WeDle.Game.Handoff.Pruner do
  @moduledoc """
  The `WeDle.Game.Handoff.Pruner` periodically deletes all
  handoffs in the database.
  """

  use GenServer

  require Logger

  alias WeDle.{Handoffs, Schemas.Handoff}

  defstruct node_status: :alive

  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

  # Prune every five minutes
  @pruning_interval 5

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    @pruning_interval
    |> to_millisecond()
    |> :timer.send_interval(:prune)

    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(:shutting_down, state), do: {:noreply, %{state | node_status: :shutting_down}}
  def handle_info(:prune, %{node_status: :shutting_down} = state), do: {:noreply, state}

  def handle_info(:prune, state) do
    Logger.info("#{__MODULE__} deleting handoffs older than three hours")

    :second
    |> Handoff.expiration_time()
    |> Handoffs.delete_handoffs_older_than(:second)

    {:noreply, state}
  end

  defp to_millisecond(minutes), do: minutes * 60_000
end
