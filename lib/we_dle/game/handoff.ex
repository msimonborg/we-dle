defmodule WeDle.Game.Handoff do
  @moduledoc """
  A CRDT that propogates and resolves game state data through the cluster
  for handoff between processes.

  A handoff is necessary to ensure that a game process can survive through
  changes to cluster topology.
  """

  alias WeDle.{Game, Game.Handoff}

  @type game :: Game.t()
  @type game_id :: String.t()
  @type value :: game | nil

  # -- Client API --

  def child_spec(_) do
    DeltaCrdt.child_spec(
      crdt: DeltaCrdt.AWLWWMap,
      name: __MODULE__,
      sync_interval: 100,
      max_sync_size: :infinite,
      shutdown: 60_000,
      on_diffs: {Handoff.Orchestrator, :process_diffs, []}
    )
  end

  @doc """
  Set the neighbors of the CRDT handoff within the cluster.
  """
  @spec set_neighbors :: :ok
  def set_neighbors do
    neighbors =
      [:visible]
      |> Node.list()
      |> Enum.map(&{__MODULE__, &1})

    DeltaCrdt.set_neighbours(__MODULE__, neighbors)
  end

  @doc """
  Puts a `game` under the key `game_id`.
  """
  @spec put(game_id, game, timeout) :: __MODULE__
  def put(game_id, %Game{} = game, timeout \\ 5000) when is_binary(game_id) do
    DeltaCrdt.put(__MODULE__, game_id, game, timeout)
  end

  @doc """
  Gets the value under the key `game_id`.
  """
  @spec get(game_id, timeout) :: value
  def get(game_id, timeout \\ 5000) when is_binary(game_id) do
    DeltaCrdt.get(__MODULE__, game_id, timeout)
  end

  @doc """
  Deletes the given `game_id`.
  """
  @spec delete(game_id, timeout) :: __MODULE__
  def delete(game_id, timeout \\ 5000) when is_binary(game_id) do
    DeltaCrdt.delete(__MODULE__, game_id, timeout)
  end

  @doc """
  Returns the current state of the `Handoff` CRDT as a map.
  """
  @spec to_map(timeout) :: %{game_id => game}
  def to_map(timeout \\ 5000) do
    DeltaCrdt.to_map(__MODULE__, timeout)
  end
end
