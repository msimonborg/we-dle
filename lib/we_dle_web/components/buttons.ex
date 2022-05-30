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

    unless assigns[:theme] do
      raise "expected :theme assign for menu button component"
    end

    ~H"""
    <button
      type="button"
      class={"bg-transparent p-1 #{text_color(@theme)}"}
      id={@id}
      aria-expanded="false"
      aria-haspopup="true"
    >
      <span class="sr-only"><%= @sr_text %></span>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp text_color(:light), do: "text-gray-600 hover:text-gray-800"
  defp text_color(:dark), do: "text-gray-200 hover:text-gray-400"
end
