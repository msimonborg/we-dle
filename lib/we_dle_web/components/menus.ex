defmodule WeDleWeb.Components.Menus do
  @moduledoc """
  A collection of menu components.
  """

  use WeDleWeb, :component

  import WeDleWeb.GameLive.Helpers

  def main_menu(assigns) do
    ~H"""
    <div class="relative z-10" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
      <!-- Background backdrop, show/hide based on slide-over state. -->
      <div class="fixed overflow-hidden">
        <div class="absolute overflow-hidden">
          <div
            x-show={@x_data_var}
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
                "flex h-full flex-col overflow-y-scroll #{background_color(@theme)} border-r #{border_color(@theme)} py-6 shadow-2xl"
              }>
                <div class="px-4 sm:px-6">
                  <div class="flex items-start justify-between">
                    <div>
                      <h2
                        class={"text-2xl font-medium font-serif #{text_color(@theme)}"}
                        id="slide-over-title"
                      >
                        we-dle
                      </h2>
                      <%= if @current_user do %>
                        <span class={"block text-sm font-light font-sans #{text_color(@theme)}"}>
                          <%= @current_user.email %>
                        </span>
                      <% end %>
                    </div>
                    <div class="ml-3 flex h-7 items-center">
                      <Components.Buttons.menu_button
                        id="close-main-menu-button"
                        sr_text="Close Main Menu"
                        theme={@theme}
                        @click={"#{@x_data_var} = ! #{@x_data_var}"}
                      >
                        <span class="sr-only">Close panel</span>
                        <Components.Icons.outline_x aria-hidden="true" />
                      </Components.Buttons.menu_button>
                    </div>
                  </div>
                </div>
                <div class="relative flex-1 px-4 sm:px-6">
                  <div class={"border #{border_color(@theme)} my-6"}></div>
                  <ul class="space-y-2">
                    <li>
                      <Components.App.link
                        to="https://github.com/msimonborg/we-dle"
                        target="_blank"
                        theme={@theme}
                      >
                        Source Code
                      </Components.App.link>
                    </li>
                    <li>
                      <Components.App.link
                        to="https://www.patreon.com/we_dle"
                        target="_blank"
                        theme={@theme}
                      >
                        Sponsor
                      </Components.App.link>
                    </li>
                    <li>
                      <Components.App.link
                        to="https://www.nytimes.com/games/wordle/"
                        target="_blank"
                        theme={@theme}
                      >
                        Play Wordle
                      </Components.App.link>
                    </li>
                    <%= if @current_user do %>
                      <li>
                        <div class={"border #{border_color(@theme)} my-6"}></div>
                      </li>
                      <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
                        <li>
                          <Components.App.link
                            to={Routes.live_dashboard_path(@socket, :home)}
                            target="_blank"
                            theme={@theme}
                          >
                            LiveDashboard
                          </Components.App.link>
                        </li>
                      <% end %>
                      <li>
                        <Components.App.link
                          to={Routes.admin_user_settings_path(@socket, :edit)}
                          target="_blank"
                          theme={@theme}
                        >
                          Settings
                        </Components.App.link>
                      </li>
                      <li>
                        <Components.App.link
                          to={Routes.admin_user_session_path(@socket, :delete)}
                          method={:delete}
                          target="_blank"
                          theme={@theme}
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
end
