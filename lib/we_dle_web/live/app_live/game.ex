defmodule WeDleWeb.AppLive.Game do
  @moduledoc """
  The live view that renders and controls the game.
  """

  use WeDleWeb, :live_view

  alias WeDleWeb.AppLive

  @impl true
  def render(assigns) do
    ~H"""
    <%= unless @env == :prod do %>
      <.expire_button />
    <% end %>
    <%= if connected?(@socket) do %>
      <Components.Game.board board={@player.board} />
    <% end %>
    """
  end

  def expire_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex items-center px-2.5 py-1.5 shadow-sm text-xs font-medium rounded text-zinc-100 bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-700"
      phx-click="expire"
    >
      expire
    </button>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    game_id = Map.fetch!(session, "game_id")
    settings = Map.fetch!(session, "settings")
    connected = connected?(socket)

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(Map.from_struct(settings))
     |> assign(:env, WeDle.config([:env]))
     |> join_game_if_connected(connected)}
  end

  defp join_game_if_connected(socket, true) do
    %{player_id: player_id, game_id: game_id} = socket.assigns

    {:ok, player} = WeDle.Game.start_or_join(game_id, player_id)

    assign(socket, :player, player)
  end

  defp join_game_if_connected(socket, false), do: socket

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end

  def handle_event("expire", _, socket) do
    %{game_id: game_id} = socket.assigns
    :ok = WeDle.Game.force_expire(game_id)
    {:noreply, redirect(socket, to: Routes.live_path(socket, AppLive.Game, game_id))}
  end
end
