defmodule WeDleWeb.Components.App do
  @moduledoc """
  The main application UI components.
  """

  use WeDleWeb, :component

  def shell(assigns) do
    assigns = assign_new(assigns, :theme, fn -> :light end)

    ~H"""
    <div class={"h-screen #{background_color(@theme)}"}>
      <nav class={"border-b #{border_color(@theme)}"}>
        <div class="max-w-full mx-auto px-4">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <!-- Main Menu -->
              <Components.Buttons.menu_button
                id="main-menu-button"
                sr_text="Open Main Menu"
                theme={@theme}
              >
                <Components.Icons.solid_menu class="h-7 w-7" />
              </Components.Buttons.menu_button>
              <!-- Help -->
              <Components.Buttons.menu_button
                id="help-menu-button"
                sr_text="Open Help Menu"
                theme={@theme}
              >
                <Components.Icons.solid_question_mark_circle class="h-7 w-7" />
              </Components.Buttons.menu_button>
            </div>
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <p class={"font-serif font-bold text-4xl #{text_color(@theme)}"}>we-dle</p>
              </div>
            </div>
            <div class="flex items-center">
              <!-- Stats -->
              <Components.Buttons.menu_button
                id="stats-menu-button"
                sr_text="Open Stats Menu"
                theme={@theme}
              >
                <Components.Icons.solid_chart_bar class="h-7 w-7" />
              </Components.Buttons.menu_button>
              <!-- Settings -->
              <Components.Buttons.menu_button
                id="settings-menu-button"
                sr_text="Open Settings Menu"
                theme={@theme}
              >
                <Components.Icons.solid_cog class="h-7 w-7" />
              </Components.Buttons.menu_button>
            </div>
          </div>
        </div>
      </nav>

      <div class="py-10">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
          <main>
            <%= render_slot(@inner_block) %>
            <Components.Menus.main_menu {assigns} />
          </main>
        </div>
      </div>
    </div>
    """
  end

  defp background_color(:light), do: "bg-white"
  defp background_color(:dark), do: "bg-black"
  defp border_color(:light), do: "border-gray-300"
  defp border_color(:dark), do: "border-gray-700"
  defp text_color(:light), do: "text-black"
  defp text_color(:dark), do: "text-white"
end
