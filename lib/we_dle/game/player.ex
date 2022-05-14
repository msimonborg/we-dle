defmodule WeDle.Game.Player do
  @moduledoc """
  The `WeDle.Game.Player` struct holds data on a player.
  """

  require Logger

  alias WeDle.Game.{Board, PlayerError}

  defstruct [:id, :game_id, :challenge, :board]

  @type option :: {:id, String.t()} | {:game_id, String.t()} | {:board, Board.t()}
  @type options :: [option]
  @type t :: %__MODULE__{
          id: String.t(),
          game_id: String.t(),
          challenge: String.t() | nil,
          board: Board.t()
        }

  @doc """
  Builds and validates a new player.
  """
  @spec new(options) :: t
  def new(opts) when is_list(opts) do
    validate_opts!(opts, :new, [:id, :game_id, :board])
    struct!(__MODULE__, opts)
  end

  defp validate_opts!(opts, fun, keys) do
    if Enum.all?(keys, &(&1 in Keyword.keys(opts))) do
      opts
    else
      reason =
        "expected #{Enum.join(keys, ", ")} to be in opts passed to " <>
          "`WeDle.Game.Player.#{fun}/1`, got #{inspect(opts)}"

      Logger.error(reason)
      raise PlayerError, reason
    end
  end
end
