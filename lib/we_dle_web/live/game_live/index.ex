defmodule WeDleWeb.GameLive.Index do
  @moduledoc """
  The live view that renders the welcome and game creation page.
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
    settings = Map.fetch!(session, "settings")
    current_user = Map.fetch!(session, "current_user")
    settings_changeset = Settings.changeset(settings, %{})

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(Map.from_struct(settings))
     |> assign(:settings_changeset, settings_changeset)}
  end
end
