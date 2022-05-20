defmodule WeDle.Game.Handoff.Orchestrator do
  @moduledoc """
  The `WeDle.Game.Handoff.Orchestrator` is in charge of
  guaranteeing handoff states are delivered to the correct
  games on the local node.
  """

  use GenServer, shutdown: 60_000

  require Logger

  alias WeDle.Game.Handoff

  defstruct [:tasksup, node_status: :alive]

  @type node_status :: :alive | :shutdown
  @type t :: %__MODULE__{
          tasksup: pid,
          node_status: node_status
        }

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  def process_diffs([]), do: :noop
  def process_diffs([{:remove, _, _}]), do: :noop

  def process_diffs(diffs) do
    diffs = for {:add, game_id, game_state} <- diffs, do: {game_id, game_state}
    GenServer.cast(__MODULE__, {:process_diffs, diffs})
  end

  @doc false
  def process_diff({game_id, game_state}) do
    case Registry.lookup(Handoff.Registry, game_id) do
      [{pid, _}] ->
        send(pid, {:handoff, game_state})
        Handoff.delete(game_id)

      [] ->
        :noop
    end
  end

  def process_diff({:remove, _, _}), do: :noop

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    {:ok, _pid} =
      Registry.start_link(
        keys: :unique,
        name: Handoff.Registry,
        partitions: System.schedulers_online()
      )

    {:ok, pid} = Task.Supervisor.start_link()

    {:ok, %__MODULE__{tasksup: pid}}
  end

  @impl true
  def handle_cast({:process_diffs, _}, %{node_status: :shutdown} = state) do
    {:noreply, state}
  end

  def handle_cast({:process_diffs, [{_, _} = diff]}, state) do
    Task.Supervisor.start_child(state.tasksup, __MODULE__, :process_diff, [diff])
    {:noreply, state}
  end

  def handle_cast({:process_diffs, diffs}, state) do
    stream =
      Task.Supervisor.async_stream_nolink(state.tasksup, diffs, __MODULE__, :process_diff, [],
        ordered: false,
        on_timeout: :kill_task,
        shutdown: :brutal_kill,
        max_concurrency: System.schedulers_online()
      )

    Task.Supervisor.start_child(state.tasksup, Enum, :to_list, [stream])

    {:noreply, state}
  end

  def handle_cast(:shutting_down, state) do
    {:noreply, %{state | node_status: :shutdown}}
  end
end
