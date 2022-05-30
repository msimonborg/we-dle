defmodule WeDleWeb.Components.Menus do
  @moduledoc """
  A collection of menu components.
  """

  use WeDleWeb, :component

  def main_menu(assigns) do
    ~H"""
    <ul>
      <%= if function_exported?(Routes, :live_dashboard_path, 2) && @current_user do %>
        <li><%= link("LiveDashboard", to: Routes.live_dashboard_path(@socket, :home)) %></li>
      <% end %>
      <%= if @current_user do %>
        <li><%= @current_user.email %></li>
        <li><%= link("Settings", to: Routes.admin_user_settings_path(@socket, :edit)) %></li>
        <li>
          <%= link("Log out",
            to: Routes.admin_user_session_path(@socket, :delete),
            method: :delete
          ) %>
        </li>
      <% else %>
        <li>
          <%= link("Register", to: Routes.admin_user_registration_path(@socket, :new)) %>
        </li>
        <li><%= link("Log in", to: Routes.admin_user_session_path(@socket, :new)) %></li>
      <% end %>
    </ul>
    """
  end
end
