defmodule WeDleWeb.Components.App do
  @moduledoc """
  The main application UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.GameLive.Helpers

  def link(assigns) do
    unless assigns[:theme] do
      raise "expected :theme assign for link component"
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
      class: "#{text_color(@theme)} #{hover_text_color(@theme)}"
    ) %>
    """
  end

  def shell(assigns) do
    ~H"""
    <div x-data="{ mainMenuOpen: false }">
      <div class={"h-screen #{background_color(@theme)}"}>
        <nav class={"border-b #{border_color(@theme)}"}>
          <div class="max-w-full mx-auto px-4">
            <div class="flex justify-between h-16">
              <div class="flex items-center">
                <!-- Main Menu -->
                <Components.Buttons.menu_button
                  id="open-main-menu-button"
                  sr_text="Open Main Menu"
                  theme={@theme}
                  @click="mainMenuOpen = ! mainMenuOpen"
                >
                  <Components.Icons.solid_menu class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Help -->
                <Components.Buttons.menu_button
                  id="open-help-menu-button"
                  sr_text="Open Help Menu"
                  theme={@theme}
                >
                  <Components.Icons.solid_question_mark_circle class="h-7 w-7" />
                </Components.Buttons.menu_button>
              </div>
              <div x-data="{bounce: false}" id="logo" phx-update="ignore" class="flex">
                <div
                  @click="bounce = ! bounce"
                  :class="bounce && 'animate-bounce'"
                  class="flex-shrink-0 flex items-center"
                >
                  <p class={"font-serif font-bold text-4xl #{text_color(@theme)}"}>
                    we-dle
                  </p>
                </div>
              </div>
              <div class="flex items-center">
                <!-- Stats -->
                <Components.Buttons.menu_button
                  id="open-stats-menu-button"
                  sr_text="Open Stats Menu"
                  theme={@theme}
                >
                  <Components.Icons.solid_chart_bar class="h-7 w-7" />
                </Components.Buttons.menu_button>
                <!-- Settings -->
                <Components.Buttons.menu_button
                  id="open-settings-menu-button"
                  sr_text="Open Settings Menu"
                  theme={@theme}
                >
                  <Components.Icons.solid_cog class="h-7 w-7" />
                </Components.Buttons.menu_button>
              </div>
            </div>
          </div>
        </nav>

        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
          <main>
            <div phx-update="ignore" id="main-menu">
              <Components.Menus.main_menu x_data_var="mainMenuOpen" {assigns} />
            </div>
            <%= render_slot(@inner_block) %>
          </main>
        </div>
      </div>
    </div>
    """
  end
end
