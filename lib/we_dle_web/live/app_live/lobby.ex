defmodule WeDleWeb.AppLive.Lobby do
  @moduledoc """
  The live view that renders the welcome and game creation page.
  """

  use WeDleWeb, :live_view

  require Logger

  alias WeDle.Game
  alias WeDleWeb.AppLive

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

    {:ok,
     socket
     |> assign(:env, WeDle.config([:env]))
     |> assign(Map.from_struct(settings))}
  end

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end

  def handle_event("start", _, socket) do
    game_id = Game.unique_id()

    case Game.start(game_id) do
      {:ok, _} ->
        {:noreply, redirect(socket, to: Routes.live_path(socket, AppLive.Game, game_id))}

      {:error, {:already_started, _}} ->
        # In the very unlikely event that the id is taken, log it and try again
        Logger.error("game ID \"#{game_id}\" is taken, generating a new one")
        handle_event("start", %{}, socket)
    end
  end
end
