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
    settings = Map.fetch!(session, "settings")
    current_user = Map.fetch!(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(Map.from_struct(settings))}
  end

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end
end
