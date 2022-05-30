defmodule WeDleWeb.GameLive.Index do
  @moduledoc """
  The live view that renders the welcome and game creation page.
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
    player_id = Map.fetch!(session, "player_id")
    current_user = Map.fetch!(session, "current_user")

    {:ok, assign(socket, player_id: player_id, current_user: current_user)}
  end
end
