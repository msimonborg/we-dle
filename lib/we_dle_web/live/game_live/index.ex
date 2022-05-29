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
  def mount(_params, %{"player_id" => player_id} = _session, socket) do
    {:ok, assign(socket, player_id: player_id)}
  end
end
