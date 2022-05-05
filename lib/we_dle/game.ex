defmodule WeDle.Game do
  @moduledoc """
  The public API for starting and stopping games, and game logic.
  """

  alias WeDle.{DistributedSupervisor, Game.Server}

  @type option :: {:player_id | :game_id, String.t()}
  @type options :: [option]

  @doc """
  Starts a new game.

  ## Options

    * `:game_id` - a unique string identifying the game (required)

    * `:player_id` - a unique string identifying the player (required)

  ## Examples

      iex> {:ok, pid} = WeDle.Game.start(game_id: "new_game", player_id: "Michael Jordan")
      iex> is_pid(pid)
      true
  """
  @spec start(options) :: WeDle.Game.Server.on_start()
  def start(opts) do
    DistributedSupervisor.start_child({Server, opts})
  end
end
