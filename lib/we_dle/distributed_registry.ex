defmodule WeDle.DistributedRegistry do
  @moduledoc """
  Uses `Horde.Registry` to globally register long running processes
  across the cluster with replicated storage backed by CRDTs.

  Must be before the `WeDle.DistributedSupervisor` in the application
  supervision tree.
  """

  use Horde.Registry

  @type name :: binary | [name_part]
  @type name_part :: {:game_id, binary} | {:player_id, binary}

  # -- Client API --

  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [keys: :unique], name: __MODULE__)
  end

  @doc """
  Returns a `:via` naming tuple for registration and lookup in the
  `WeDle.DistributedRegistry`.
  """
  @spec via_tuple(name) :: {:via, Horde.Registry, {__MODULE__, name}}
  def via_tuple(name) when is_binary(name) or is_list(name),
    do: {:via, Horde.Registry, {__MODULE__, name}}

  # -- Callbacks --

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  defp members do
    Node.list([:visible, :this])
    |> Enum.map(&{__MODULE__, &1})
  end
end
