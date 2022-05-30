defmodule WeDleWeb.GameLive.Show do
  @moduledoc """
  The live view that renders and controls the game.
  """

  use WeDleWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= @player_id %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    game_id = Map.fetch!(session, "game_id")
    player_id = Map.fetch!(session, "player_id")
    current_user = Map.fetch!(session, "current_user")

    {:ok, assign(socket, player_id: player_id, current_user: current_user, game_id: game_id)}
  end
end
