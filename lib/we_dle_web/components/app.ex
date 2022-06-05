defmodule WeDleWeb.Components.App do
  @moduledoc """
  The main application UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def link(assigns) do
    unless assigns[:dark_theme] do
      raise "expected :dark_theme assign for link component"
    end

    unless assigns[:to] do
      raise "expected :to assign for link component"
    end

    assigns =
      assigns
      |> assign_new(:method, fn -> :get end)
      |> assign_new(:target, fn -> false end)

    ~H"""
    <%= link(render_slot(@inner_block),
      to: @to,
      method: @method,
      target: @target,
      class: "#{text_color(@dark_theme)} #{hover_text_color(@dark_theme)}"
    ) %>
    """
  end

  def shell(assigns) do
    ~H"""
    <div x-data="{ mainMenuOpen: false, settingsOpen: false }">
      <div class={"h-screen #{background_color(@dark_theme)}"}>
        <nav class={"border-b #{border_color(@dark_theme)}"}>
          <div class="max-w-full mx-auto px-4">
            <div class="flex justify-between h-16">
              <div class="flex items-center">
                <!-- Main Menu -->
                <Components.Buttons.menu_button
                  id="open-main-menu-button"
                  sr_text="Open Main Menu"
                  dark_theme={@dark_theme}
                  :aria-expanded="mainMenuOpen"
                  @click="mainMenuOpen = ! mainMenuOpen"
                >
                  <Components.Icons.solid_menu class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Help -->
                <Components.Buttons.menu_button
                  id="open-help-menu-button"
                  sr_text="Open Help Menu"
                  dark_theme={@dark_theme}
                  :aria-expanded="false"
                >
                  <Components.Icons.solid_question_mark_circle class="h-7 w-7" />
                </Components.Buttons.menu_button>
              </div>
              <!-- Logo -->
              <div x-data="{bounce: false}" id="logo" class="flex">
                <div
                  @click="bounce = ! bounce"
                  :class="bounce && 'animate-bounce'"
                  class="flex-shrink-0 flex items-center"
                >
                  <span class={"font-serif font-bold text-4xl #{text_color(@dark_theme)}"}>
                    we-dle
                  </span>
                </div>
              </div>
              <div class="flex items-center">
                <!-- Stats -->
                <Components.Buttons.menu_button
                  id="open-stats-menu-button"
                  sr_text="Open Stats Menu"
                  dark_theme={@dark_theme}
                  :aria-expanded="false"
                >
                  <Components.Icons.solid_chart_bar class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Settings -->
                <Components.Buttons.menu_button
                  id="open-settings-menu-button"
                  sr_text="Open Settings Menu"
                  dark_theme={@dark_theme}
                  :aria-expanded="settingsOpen"
                  @click="settingsOpen = ! settingsOpen"
                >
                  <Components.Icons.solid_cog class="h-7 w-7" />
                </Components.Buttons.menu_button>
              </div>
            </div>
          </div>
        </nav>

        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
          <main>
            <div id="main-menu">
              <Components.Menus.main_menu open_state="mainMenuOpen" {assigns} />
            </div>
            <div id="settings">
              <Components.Menus.settings open_state="settingsOpen" {assigns} />
            </div>
            <%= render_slot(@inner_block) %>
          </main>
        </div>
      </div>
    </div>
    <!-- This iframe provides a target for hidden form submissions and HTTP requests -->
    <!-- that mutate the session state. -->
    <iframe hidden name="hidden_iframe" src={Routes.iframe_path(@socket, :index)} height="0" width="0">
    </iframe>
    """
  end
end
