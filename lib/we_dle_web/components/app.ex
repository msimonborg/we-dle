defmodule WeDleWeb.Components.App do
  @moduledoc """
  The main application UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def link(assigns) do
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
      class: "#{text_color()} #{hover_text_color()}"
    ) %>
    """
  end

  def shell(assigns) do
    ~H"""
    <div
      id="app-shell"
      class={[(@dark_theme == 1 and "dark") || "light"]}
      x-data="{ mainMenuOpen: false, settingsOpen: false }"
    >
      <div class={"h-screen #{background_color()}"}>
        <nav class={"border-b #{border_color()}"}>
          <div class="max-w-full mx-auto px-4">
            <div class="flex justify-between h-16">
              <div class="flex items-center">
                <!-- Main Menu -->
                <Components.Buttons.menu_button
                  id="open-main-menu-button"
                  sr_text="Open Main Menu"
                  :aria-expanded="mainMenuOpen"
                  @click="mainMenuOpen = ! mainMenuOpen"
                >
                  <Components.Icons.solid_menu class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Help -->
                <Components.Buttons.menu_button
                  id="open-help-menu-button"
                  sr_text="Open Help Menu"
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
                  <span class={"font-serif font-bold text-4xl #{text_color()}"}>
                    we-dle
                  </span>
                </div>
              </div>
              <div class="flex items-center">
                <!-- Stats -->
                <Components.Buttons.menu_button
                  id="open-stats-menu-button"
                  sr_text="Open Stats Menu"
                  :aria-expanded="false"
                >
                  <Components.Icons.solid_chart_bar class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Settings -->
                <Components.Buttons.menu_button
                  id="open-settings-menu-button"
                  sr_text="Open Settings Menu"
                  :aria-expanded="settingsOpen"
                  @click="settingsOpen = ! settingsOpen"
                >
                  <Components.Icons.solid_cog class="h-7 w-7" />
                </Components.Buttons.menu_button>
              </div>
            </div>
          </div>
          <div id="main-menu">
            <Components.Menus.main_menu open_state="mainMenuOpen" {assigns} />
          </div>
          <div id="settings">
            <Components.Menus.settings open_state="settingsOpen" {assigns} />
          </div>
        </nav>

        <main class="h-[calc(100%_-_65px)] w-full max-w-[500px] m-auto flex flex-col">
          <%= render_slot(@inner_block) %>
        </main>
      </div>
    </div>
    """
  end
end
