defmodule WeDle.Game.Handoff.NotificationStore do
  @moduledoc """
  The `WeDle.Game.Handoff.NotificationStore` is a `GenServer`
  that owns an ETS table to store a short-term record of the
  handoff notifications.

  A full scan of the table is performed every two minutes to
  delete any keys that are older than the interval.
  """

  use GenServer

  require Logger

  defstruct node_status: :alive

  @type t :: %__MODULE__{node_status: :alive | :shutting_down}

  # 120 seconds
  @interval 120
  @name __MODULE__

  # -- Client API --

  @doc """
  Checks if their is a corresponding handoff notification for
  `game_id`.
  """
  @spec contains?(String.t()) :: boolean
  def contains?(game_id) do
    case :ets.lookup(@name, game_id) do
      [{^game_id, _}] -> true
      _ -> false
    end
  end

  @doc """
  Deletes the given `game_id` from the store.
  """
  @spec delete(String.t()) :: true
  def delete(game_id) do
    :ets.delete(@name, game_id)
  end

  @doc """
  Inserts the given `game_id` into the store.
  """
  def insert(game_id) do
    :ets.insert(@name, {game_id, DateTime.utc_now()})
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

  defp prune_table do
    Logger.info("begin pruning WeDle.Game.Handoff.NotificationStore")

    :ets.safe_fixtable(@name, true)

    @name
    |> :ets.first()
    |> prune_table()

    :ets.safe_fixtable(@name, false)

    Logger.info("finished pruning WeDle.Game.Handoff.NotificationStore")
  end

  defp prune_table(:"$end_of_table"), do: :ok

  defp prune_table(game_id) do
    case :ets.lookup(@name, game_id) do
      [{^game_id, date_time}] ->
        now = DateTime.utc_now()
        diff = DateTime.diff(now, date_time)
        if diff >= @interval, do: delete(game_id)

      _ ->
        :noop
    end

    @name
    |> :ets.next(game_id)
    |> prune_table()
  end
end
