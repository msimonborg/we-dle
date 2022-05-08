defmodule WeDle.Game.EdgeServer do
  @moduledoc """
  The `WeDle.Game.EdgeServer` is a process that runs locally
  on the same node as the player, providing fast computation
  and an interface to the `WeDle.Game.Server`.
  """

  use GenServer

  alias WeDle.Game.EdgeRegistry

  @type name :: {:via, Registry, {EdgeRegistry, String.t()}}

  # -- Client API --

  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    player_id = Keyword.fetch!(opts, :player_id)
    GenServer.start_link(__MODULE__, opts, name: name(game_id, player_id))
  end

  @doc """
  Returns a `:via` tuple to register and lookup `WeDle.Game.EdgeServer`
  processes on the local node.
  """
  @spec name(String.t(), String.t()) :: name
  def name(game_id, player_id) do
    {:via, Registry, {EdgeRegistry, "#{player_id}@#{game_id}"}}
  end

  # -- Callbacks --

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end
end
