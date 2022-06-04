defmodule WeDleWeb.Components.Buttons do
  @moduledoc """
  A collection of button components.
  """

  use WeDleWeb, :component

  def menu_button(assigns) do
    unless assigns[:sr_text] do
      raise "expected :sr_text assign for menu button component"
    end

    unless assigns[:id] do
      raise "expected :id assign for menu button component"
    end

    unless assigns[:dark_theme] do
      raise "expected :dark_theme assign for menu button component"
    end

    extras = assigns_to_attributes(assigns, [:sr_text, :id, :dark_theme])
    assigns = assign(assigns, :extras, extras)

    ~H"""
    <button
      type="button"
      class={"bg-transparent p-1 #{text_color(@dark_theme)}"}
      id={@id}
      aria-haspopup="true"
      {@extras}
    >
      <span class="sr-only"><%= @sr_text %></span>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def toggle_button(assigns) do
    unless assigns[:field] do
      raise "expected :field assign for toggle_input component"
    end

    unless assigns[:value] do
      raise "expected :value assign for toggle_input component"
    end

    unless assigns[:sr_text] do
      raise "expected :sr_text assign for toggle_input component"
    end

    ~H"""
    <div x-data={"{value: #{@value}}"} class="ml-3 flex items-center h-5">
      <!-- Enabled: "bg-green-600", Not Enabled: "bg-zinc-400" -->
      <button
        aria-checked={"#{@value == 1}"}
        type="button"
        name={"toggle_#{@field}"}
        phx-click={"change_#{@field}"}
        class={
          if(@value == 1, do: "bg-green-600", else: "bg-zinc-400") <>
            " relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        }
      >
        <span class="sr-only"><%= @sr_text %></span>
        <!-- Enabled: "translate-x-5", Not Enabled: "translate-x-0" -->
        <span
          aria-hidden="true"
          class={
            if(@value == 0, do: "translate-x-0", else: "translate-x-5") <>
              " pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200"
          }
        >
        </span>
      </button>
    </div>
    """
  end

  defp text_color(0 = _dark_theme), do: "text-zinc-600 hover:text-zinc-800"
  defp text_color(1 = _dark_theme), do: "text-zinc-200 hover:text-zinc-400"
end
