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
    %{"player_id" => player_id, "game_id" => game_id} = session
    {:ok, assign(socket, player_id: player_id, game_id: game_id)}
  end
end
