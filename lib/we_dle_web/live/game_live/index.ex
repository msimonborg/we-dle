defmodule WeDleWeb.GameLive.Index do
  @moduledoc """
  The live view that renders the welcome and game creation page.
  """

  use WeDleWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= unless @env == :prod do %>
      <.start_button />
    <% end %>
    """
  end

  def start_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex items-center px-2.5 py-1.5 shadow-sm text-xs font-medium rounded text-zinc-100 bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-700"
      phx-click="start"
    >
      start
    </button>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    settings = Map.fetch!(session, "settings")
    current_user = Map.fetch!(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:env, WeDle.Application.runtime_env())
     |> assign(Map.from_struct(settings))}
  end

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end

  def handle_event("start", _, socket) do
    game_id = WeDle.Game.unique_id()
    {:ok, _} = WeDle.Game.start_or_join(game_id, socket.assigns.player_id)
    {:noreply, redirect(socket, to: Routes.game_path(socket, :show, game_id))}
  end
end
