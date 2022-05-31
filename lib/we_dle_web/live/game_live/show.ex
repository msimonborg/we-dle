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
    settings = Map.fetch!(session, "settings")
    current_user = Map.fetch!(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:game_id, game_id)
     |> assign(Map.from_struct(settings))}
  end
end
