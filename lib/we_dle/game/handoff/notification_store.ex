defmodule WeDle.Game.Handoff.NotificationStore do
  @moduledoc """
  The `WeDle.Game.Handoff.NotificationStore` an ETS table which
  stores a short-term record of the handoff notifications.

  A full scan of the table is performed by the owning process
  every two minutes to delete any keys that are older than the
  interval.
  """

  use GenServer

  require Logger

  defstruct node_status: :alive

  @type game_id :: String.t()
  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

  # 120 seconds
  @interval 120
  @name __MODULE__

  @doc """
  Compile-time guard that checks if `unit` is a valid `t:System.time_unit/0` value.
  """
  defguard is_time_unit(unit)
           when unit in [:nanosecond, :microsecond, :millisecond, :second] or
                  (is_integer(unit) and unit > 0)

  # -- Client API --

  @doc """
  Checks if their is a corresponding handoff notification for
  `game_id`.
  """
  @spec contains?(game_id) :: boolean
  def contains?(game_id) when is_binary(game_id) do
    case :ets.lookup(@name, game_id) do
      [{^game_id, _}] -> true
      _ -> false
    end
  end

  @doc """
  Deletes the given `game_id` from the store.
  """
  @spec delete(game_id) :: :ok
  def delete(game_id) when is_binary(game_id) do
    true = :ets.delete(@name, game_id)
    :ok
  end

  @doc """
  Inserts the given `game_id` into the store.
  """
  @spec insert(game_id) :: :ok
  def insert(game_id) when is_binary(game_id) do
    true = :ets.insert(@name, {game_id, DateTime.utc_now()})
    :ok
  end

  @doc """
  Prunes the table, deleting all `game_id`s that were inserted
  more than two minutes ago.

  The full table scan is performed synchronously by the calling
  process, which blocks until the scan is complete. Calling this
  function directly is not required when this module is added as
  a child to a supervisor, since the gen_server which owns the
  table will automatically prune it every two minutes.
  """
  @spec prune_table :: :ok
  def prune_table, do: prune_table(@interval)

  @doc """
  Prunes the table, deleting all `game_id`s that were inserted
  longer than `interval` time ago. Takes an optional `unit`,
  which can be any unit from `t:System.time_unit/0`. The default
  `unit` is `:second`.

  See `prune_table/0` for more info.
  """
  @spec prune_table(interval :: non_neg_integer, System.time_unit()) :: :ok
  def prune_table(interval, unit \\ :second)
      when is_integer(interval) and interval >= 0 and is_time_unit(unit) do
    Logger.info("begin pruning WeDle.Game.Handoff.NotificationStore")

    :ets.safe_fixtable(@name, true)

    :ok =
      @name
      |> :ets.first()
      |> prune_table(interval, unit)

    :ets.safe_fixtable(@name, false)

    Logger.info("finished pruning WeDle.Game.Handoff.NotificationStore")
    :ok
  end

  defp prune_table(:"$end_of_table", _, _), do: :ok

  defp prune_table(game_id, interval, unit) do
    case :ets.lookup(@name, game_id) do
      [{^game_id, date_time}] ->
        now = DateTime.utc_now()
        diff = DateTime.diff(now, date_time, unit)
        if diff >= interval, do: delete(game_id)

      _ ->
        :noop
    end

    @name
    |> :ets.next(game_id)
    |> prune_table(interval, unit)
  end

  @doc false
  def start_link(init_arg) do
    GenServer.start_link(@name, init_arg, name: @name)
  end

  # -- Callbacks --

  @impl true
  def init(_) do
    :ets.new(@name, [
      :named_table,
      :public,
      write_concurrency: :auto,
      read_concurrency: true
    ])

    @interval
    |> :timer.seconds()
    |> :timer.send_interval(:prune_table)

    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(_, %{node_status: :shutting_down} = state), do: {:noreply, state}
  def handle_info(:shutting_down, state), do: {:noreply, %{state | node_status: :shutting_down}}

  def handle_info(:prune_table, state) do
    prune_table()
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("""
    WeDle.Game.Handoff.NotificationStore received unexpected message in `handle_info/2`:

      #{inspect(msg)}
    """)

    {:noreply, state}
  end
end
