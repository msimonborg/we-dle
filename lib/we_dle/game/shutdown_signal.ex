defmodule WeDle.Game.ShutdownSignal do
  @moduledoc """
  Watches for system shutdowns and signals processes that need
  to change their behavior during shutdown.
  """

  use GenServer

  defstruct subscribers: []

  # -- Client API --

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # -- Callbacks --

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, struct!(__MODULE__, Keyword.put_new(opts, :subscribers, []))}
  end

  @impl true
  def terminate(:shutdown, state), do: signal_shutdown(state)
  def terminate({:shutdown, _}, state), do: signal_shutdown(state)
  def terminate(_, _), do: :ok

  defp signal_shutdown(%{subscribers: subscribers}) do
    for subscriber <- subscribers, do: send(subscriber, :shutting_down)
    :ok
  end
end
