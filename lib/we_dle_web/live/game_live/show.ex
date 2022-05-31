defmodule WeDleWeb.GameLive.Show do
  @moduledoc """
  The live view that renders and controls the game.
  """

  use WeDleWeb, :live_view

  alias WeDleWeb.Settings

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
    settings_changeset = Settings.changeset(settings, %{})

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(:current_user, current_user)
     |> assign(Map.from_struct(settings))
     |> assign(:settings_changeset, settings_changeset)}
  end
end
