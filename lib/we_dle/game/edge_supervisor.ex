defmodule WeDle.Game.EdgeSupervisor do
  @moduledoc """
  A `DynamicSupervisor` that starts and supervises
  `WeDle.Game.EdgeServer`s locally on the same node as the
  player.
  """

  use DynamicSupervisor

  # -- Client API --

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
