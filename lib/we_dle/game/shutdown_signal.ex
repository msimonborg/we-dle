defmodule WeDle.Game.ShutdownSignal do
  @moduledoc """
  Watches for system shutdowns and signals processes that need
  to change their behavior during shutdown.
  """

  use GenServer

  alias WeDle.Game.Handoff

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    Process.flag(:trap_exit, true)
    {:ok, []}
  end

  @impl true
  def terminate(:shutdown, _state), do: signal_shutdown()
  def terminate({:shutdown, _}, _state), do: signal_shutdown()

  defp signal_shutdown do
    GenServer.cast(Handoff.Orchestrator, :shutting_down)
    GenServer.cast(Handoff.Pruner, :shutting_down)
  end
end
