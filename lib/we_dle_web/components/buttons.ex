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
      aria-expanded="false"
      aria-haspopup="true"
      {@extras}
    >
      <span class="sr-only"><%= @sr_text %></span>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp text_color(0 = _dark_theme), do: "text-zinc-600 hover:text-zinc-800"
  defp text_color(1 = _dark_theme), do: "text-zinc-200 hover:text-zinc-400"
end
