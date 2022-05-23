defmodule WeDle.Game.Handoff.Worker do
  @moduledoc """
  The `WeDle.Game.Handoff.Worker` is in charge of
  guaranteeing handoff states are delivered to the correct
  games on the local node.

  The worker listens to notifications on a Postgres pubsub
  channel called "handoff_inserted", forwarding the
  notification to the game process if it exists on the local
  node.
  """

  use GenServer

  require Logger

  alias Postgrex.Notifications
  alias WeDle.Game.Handoff

  defstruct [:listener_ref, handoffs: [], counter: 0, node_status: :alive]

  @type node_status :: :alive | :shutting_down
  @type t :: %__MODULE__{listener_ref: reference, node_status: node_status}

  @channel "handoff_inserted"

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    Process.flag(:trap_exit, true)
    ref = Notifications.listen!(Handoff.Listener, @channel)
    {:ok, %__MODULE__{listener_ref: ref}}
  end

  @impl true
  def handle_info(_, %{node_status: :shutting_down} = state), do: {:noreply, state}

  def handle_info(msg, %{counter: counter} = state) when counter >= 100 do
    process_handoffs(state.handoffs)
    handle_info(msg, %{state | handoffs: [], counter: 0})
  end

  def handle_info({:notification, _, ref, @channel, payload}, %{listener_ref: ref} = state) do
    {:noreply, %{state | handoffs: [payload | state.handoffs], counter: state.counter + 1}, 5}
  end

  def handle_info(:timeout, state) do
    process_handoffs(state.handoffs)
    {:noreply, %{state | handoffs: [], counter: 0}}
  end

  defp process_handoffs(handoffs) do
    stream =
      Task.Supervisor.async_stream_nolink(
        Handoff.TaskSup,
        handoffs,
        &forward_if_game_is_local/1,
        ordered: false,
        on_timeout: :kill_task,
        shutdown: :brutal_kill,
        max_concurrency: System.schedulers_online()
      )

    Task.Supervisor.start_child(Handoff.TaskSup, Enum, :to_list, [stream])
  end

  defp forward_if_game_is_local(handoff) do
    case Registry.lookup(Handoff.Registry, handoff) do
      [{pid, _}] ->
        send(pid, :handoff_available)

      [] ->
        :ok
    end
  end

  @impl true
  def handle_cast(:shutting_down, state) do
    {:noreply, %{state | node_status: :shutting_down}}
  end

  @impl true
  def terminate(_reason, %{listener_ref: ref}) do
    Notifications.unlisten!(Handoff.Listener, ref)
  end
end
