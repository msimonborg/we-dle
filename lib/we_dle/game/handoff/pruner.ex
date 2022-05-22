defmodule WeDle.Game.Handoff.Pruner do
  @moduledoc """
  The `WeDle.Game.Handoff.Pruner` keeps all game ids with handoff state
  in an ETS table, and periodically scans the table for old processes
  that can be pruned from the handoff map.
  """

  use GenServer

  alias WeDle.Game.Handoff

  defstruct [:ets, node_status: :alive]

  @type node_status :: :alive | :shutdown
  @type t :: %__MODULE__{node_status: node_status, ets: reference}

  # Prune every ten minutes
  @pruning_interval 1_000 * 60 * 10

  # -- Client API --

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  def process_diffs([]), do: :noop
  def process_diffs(diffs), do: GenServer.cast(__MODULE__, {:process_diffs, diffs})

  @doc false
  def process_diff({:add, game_id, _}, ets) do
    :ets.insert(ets, {game_id, DateTime.utc_now()})
  end

  def process_diff({:remove, game_id}, ets) do
    :ets.delete(ets, game_id)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    send(self(), :prune)
    ets = :ets.new(:pruner_table, [:public])
    :timer.send_interval(@pruning_interval, :prune)
    {:ok, %__MODULE__{ets: ets}}
  end

  @impl true
  def handle_info(:prune, %{ets: ets} = state) do
    :ets.safe_fixtable(ets, true)

    ets
    |> :ets.first()
    |> prune(ets)

    :ets.safe_fixtable(ets, false)
    {:noreply, state}
  end

  defp prune(game_id, ets) when is_binary(game_id) do
    Task.Supervisor.start_child(Handoff.TaskSup, fn -> do_prune(game_id, ets) end)

    ets
    |> :ets.next(game_id)
    |> prune(ets)
  end

  defp prune(:"$end_of_table", _), do: :ok

  defp do_prune(game_id, ets) do
    with [{^game_id, insertion_time}] <- :ets.lookup(ets, game_id),
         true <- handoff_stale?(insertion_time) do
      :ets.delete(ets, game_id)
      Handoff.delete(game_id)
    end
  end

  defp handoff_stale?(insertion_time) do
    diff =
      DateTime.utc_now()
      |> DateTime.diff(insertion_time, :millisecond)

    diff >= @pruning_interval
  end

  @impl true
  def handle_cast({:process_diffs, _}, %{node_status: :shutdown} = state) do
    {:noreply, state}
  end

  def handle_cast({:process_diffs, [{_, _} = diff]}, state) do
    Task.Supervisor.start_child(Handoff.TaskSup, __MODULE__, :process_diff, [diff, state.ets])
    {:noreply, state}
  end

  def handle_cast({:process_diffs, diffs}, state) do
    stream =
      Task.Supervisor.async_stream_nolink(
        Handoff.TaskSup,
        diffs,
        __MODULE__,
        :process_diff,
        [state.ets],
        ordered: false,
        on_timeout: :kill_task,
        shutdown: :brutal_kill,
        max_concurrency: System.schedulers_online()
      )

    Task.Supervisor.start_child(Handoff.TaskSup, Enum, :to_list, [stream])

    {:noreply, state}
  end

  def handle_cast(:shutting_down, state) do
    {:noreply, %{state | node_status: :shutdown}}
  end
end
