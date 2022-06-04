defmodule WeDleWeb.Components.Menus do
  @moduledoc """
  A collection of menu components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def main_menu(assigns) do
    ~H"""
    <div class="relative z-10" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
      <!-- Background backdrop, show/hide based on slide-over state. -->
      <div class="fixed overflow-hidden">
        <div class="absolute overflow-hidden">
          <div
            x-cloak
            x-show={@open_state}
            x-transition:enter="transform transition ease-in-out duration-500"
            x-transition:enter-start="-translate-x-full"
            x-transition:enter-end="-translate-x-0"
            x-transition:leave="transform transition ease-in-out duration-500"
            x-transition:leave-start="-translate-x-0"
            x-transition:leave-end="-translate-x-full"
            class="pointer-events-none fixed h-full left-0 flex max-w-full"
          >
            <div class="pointer-events-auto w-screen sm:max-w-sm">
              <div class={
                "flex h-full flex-col overflow-y-scroll #{background_color(@dark_theme)} border-r #{border_color(@dark_theme)} py-6 shadow-2xl"
              }>
                <div class="px-4 sm:px-6">
                  <div class="flex items-start justify-between">
                    <div>
                      <h2
                        class={"text-2xl font-medium font-serif #{text_color(@dark_theme)}"}
                        id="slide-over-title"
                      >
                        we-dle
                      </h2>
                      <%= if @current_user do %>
                        <span class={"block text-sm font-light font-sans #{text_color(@dark_theme)}"}>
                          <%= @current_user.email %>
                        </span>
                      <% end %>
                    </div>
                    <div class="ml-3 flex h-7 items-center">
                      <Components.Buttons.menu_button
                        id="close-main-menu-button"
                        sr_text="Close Main Menu"
                        dark_theme={@dark_theme}
                        @click={"#{@open_state} = ! #{@open_state}"}
                      >
                        <Components.Icons.outline_x aria-hidden={"! #{@open_state}"} />
                      </Components.Buttons.menu_button>
                    </div>
                  </div>
                </div>
                <div class="relative flex-1 px-4 sm:px-6">
                  <div class={"border #{border_color(@dark_theme)} my-6"}></div>
                  <ul class="space-y-2">
                    <li>
                      <Components.App.link
                        to="https://github.com/msimonborg/we-dle"
                        target="_blank"
                        dark_theme={@dark_theme}
                      >
                        Source Code
                      </Components.App.link>
                    </li>
                    <li>
                      <Components.App.link
                        to="https://www.patreon.com/we_dle"
                        target="_blank"
                        dark_theme={@dark_theme}
                      >
                        Sponsor
                      </Components.App.link>
                    </li>
                    <li>
                      <Components.App.link
                        to="https://www.nytimes.com/games/wordle/"
                        target="_blank"
                        dark_theme={@dark_theme}
                      >
                        Play Wordle
                      </Components.App.link>
                    </li>
                    <%= if @current_user do %>
                      <li>
                        <div class={"border #{border_color(@dark_theme)} my-6"}></div>
                      </li>
                      <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
                        <li>
                          <Components.App.link
                            to={Routes.live_dashboard_path(@socket, :home)}
                            target="_blank"
                            dark_theme={@dark_theme}
                          >
                            LiveDashboard
                          </Components.App.link>
                        </li>
                      <% end %>
                      <li>
                        <Components.App.link
                          to={Routes.admin_user_settings_path(@socket, :edit)}
                          target="_blank"
                          dark_theme={@dark_theme}
                        >
                          Settings
                        </Components.App.link>
                      </li>
                      <li>
                        <Components.App.link
                          to={Routes.admin_user_session_path(@socket, :delete)}
                          method={:delete}
                          target="_blank"
                          dark_theme={@dark_theme}
                        >
                          Log out
                        </Components.App.link>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def settings(assigns) do
    ~H"""
    <!-- This example requires Tailwind CSS v2.0+ -->
    <div class="relative z-10" aria-labelledby="settings" role="dialog" aria-modal="true">
      <!-- Background backdrop, show/hide based on modal state. -->
      <div
        x-cloak
        x-show={@open_state}
        x-transition:enter="ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        class={"fixed inset-0 #{background_color(@dark_theme)} transition-opacity"}
      >
      </div>

      <div class="fixed z-10 inset-x-0 top-2 overflow-y-auto">
        <div class="flex items-end sm:items-center justify-center min-h-full text-center">
          <!-- Modal panel, show/hide based on modal state. -->
          <div
            x-cloak
            x-show={@open_state}
            x-transition:enter="ease-out duration-300"
            x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
            x-transition:leave="ease-in duration-200"
            x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100"
            x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            class={
              "relative #{background_color(@dark_theme)} px-4 pt-5 pb-4 text-left overflow-hidden transform transition-all max-w-md w-full p-6"
            }
          >
            <div class="block absolute top-0 right-0 pt-4 pr-4">
              <Components.Buttons.menu_button
                sr_text="Close Settings Menu"
                id="close-settings"
                dark_theme={@dark_theme}
                @click={"#{@open_state} = ! #{@open_state}"}
              >
                <Components.Icons.outline_x />
              </Components.Buttons.menu_button>
            </div>
            <.form let={f} for={:settings} action="#">
              <div class="flex justify-center">
                <h2 class={"text-lg font-bold #{text_color(@dark_theme)}"}>SETTINGS</h2>
              </div>
              <div class={"divide-y #{divide_color(@dark_theme)}"}>
                <.settings_menu_input
                  form={f}
                  field={:hard_mode}
                  label="Hard Mode"
                  value={@hard_mode}
                  sr_text="Toggle Hard Mode"
                  {assigns}
                />
                <.settings_menu_input
                  form={f}
                  field={:dark_theme}
                  label="Dark Theme"
                  value={@dark_theme}
                  sr_text="Toggle Dark Theme"
                  {assigns}
                />
                <.settings_menu_input
                  form={f}
                  field={:high_contrast}
                  label="High Contrast Mode"
                  value={@high_contrast}
                  sr_text="Toggle High Contrast Mode"
                  {assigns}
                />
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp settings_menu_input(assigns) do
    ~H"""
    <div class="relative flex items-start py-6">
      <div class={"min-w-0 flex-1 #{text_color(@dark_theme)} text-sm font-medium text-lg"}>
        <%= label(@form, @field, @label) %>
      </div>
      <Components.Form.toggle_input
        form={@form}
        field={@field}
        label={@label}
        value={@value}
        {assigns}
      />
    </div>
    """
  end
end
