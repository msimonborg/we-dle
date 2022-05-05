defmodule WeDle.Game.Server do
  @moduledoc """
  The `WeDle.Game.Server` holds the game state and publishes
  events to subscribers of that game.
  """

  use GenServer, shutdown: 10_000, restart: :transient

  require Logger

  @type on_start :: {:ok, pid} | :ignore | {:error, {ArgumentError, stacktrace :: list}}

  @doc """
  Starts and links a new game server.

  Normally this will be done indirectly by passing the child
  spec to a supervisor, such as the `WeDle.DistributedSupervisor`.
  """
  @spec start_link(keyword) :: on_start
  def start_link(opts) when is_list(opts) do
    name_keys = [:game_id, :player_id]
    {name, _} = Keyword.split(opts, name_keys)
    validate_presence_of_name_keys!(name, name_keys)

    case GenServer.start_link(__MODULE__, [], name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  defp validate_presence_of_name_keys!(name, name_keys) do
    if Enum.all?(name_keys, &(&1 in Keyword.keys(name))) do
      :ok
    else
      reason =
        "expected :game_id and :player_id to be in opts passed to " <>
          "`WeDle.Game.Server`, got #{inspect(name)}"

      raise ArgumentError, reason
    end
  end

  def init(_args) do
    {:ok, nil}
  end

  def via_tuple(name), do: WeDle.DistributedRegistry.via_tuple(name)
end
