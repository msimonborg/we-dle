defmodule WeDle.Game.Handoff.Listener do
  @moduledoc """
  The `WeDle.Game.Handoff.Listener` is in charge of
  guaranteeing handoff states are delivered to the correct
  games on the local node.

  The process listens to notifications on a Postgres pubsub
  channel called "handoff_inserted", forwarding the
  notification to the game process if it exists on the local
  node.

  We broadcast messages with Postgres on INSERT instead of using
  `Phoenix.PubSub` because we are interested in knowing when the
  record is actually available to read from the database, not when
  the application code makes the insertion. This may be especially
  important in a cluster when reading from read-only replicas, as
  it is possible that a `Phoenix.PubSub` message is received on a
  remote node before the insertion propogates to the nearest replica.
  """

  use GenServer

  require Logger

  alias Postgrex.Notifications
  alias WeDle.Game.Handoff

  defstruct [:notifier_ref, handoffs: [], counter: 0, node_status: :alive]

  @type t :: %__MODULE__{
          notifier_ref: reference,
          counter: non_neg_integer,
          handoffs: [String.t()],
          node_status: :alive | :shutting_down
        }

  @channel "handoff_inserted"
  @notifier Handoff.Notifier

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    {:ok, %__MODULE__{}, {:continue, :start_listening}}
  end

  @impl true
  def handle_continue(:start_listening, state) do
    Process.monitor(@notifier)
    {_, ref} = Notifications.listen(@notifier, @channel)
    {:noreply, %{state | notifier_ref: ref}}
  end

  @impl true
  def handle_info(_, %{node_status: :shutting_down} = state), do: {:noreply, state}
  def handle_info(:shutting_down, state), do: {:noreply, %{state | node_status: :shutting_down}}
  def handle_info(:timeout, state), do: {:noreply, process_handoffs(state)}

  def handle_info(msg, %{counter: counter} = state) when counter >= 100 do
    handle_info(msg, process_handoffs(state))
  end

  def handle_info({:notification, _, ref, @channel, payload}, %{notifier_ref: ref} = state) do
    {:noreply, %{state | handoffs: [payload | state.handoffs], counter: state.counter + 1}, 5}
  end

  def handle_info({:DOWN, ref, _, _, reason}, %{notifier_ref: ref} = state) do
    Process.demonitor(ref, [:flush])

    Logger.error(
      "#{@notifier} down with reason #{reason}",
      label: "#{__MODULE__} exiting"
    )

    {:stop, reason, %{state | notifier_ref: nil}}
  end

  defp process_handoffs(%{handoffs: handoffs} = state) do
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

    %{state | handoffs: [], counter: 0}
  end

  defp forward_if_game_is_local(handoff) do
    case Registry.lookup(Handoff.Registry, handoff) do
      [{pid, _}] -> send(pid, :handoff_available)
      [] -> :ok
    end
  end
end
