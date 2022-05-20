defmodule WeDle.Game.Handoff.Supervisor do
  @moduledoc """
  Supervises the processes responsible for handing off game state
  between game restarts.
  """

  use Supervisor

  alias WeDle.Game.Handoff

  # -- Client API --

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # -- Callbacks --

  @impl true
  def init(_init_arg) do
    children = [
      Handoff.Orchestrator,
      Handoff
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
