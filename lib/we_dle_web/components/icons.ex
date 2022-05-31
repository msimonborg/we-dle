defmodule WeDleWeb.Components.Icons do
  @moduledoc """
  A collection of SVG heroicons.

  Source: heroicons.com
  """

  use WeDleWeb, :component

  @doc """
  Heroicon name: solid/chart-bar
  """
  def solid_chart_bar(assigns) do
    ~H"""
    <.solid {assigns}>
      <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z" />
    </.solid>
    """
  end

  @doc """
  Heroicon name: solid/cog
  """
  def solid_cog(assigns) do
    ~H"""
    <.solid {assigns}>
      <path
        fill-rule="evenodd"
        d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
        clip-rule="evenodd"
      />
    </.solid>
    """
  end

  @doc """
  Heroicon name: solid/menu
  """
  def solid_menu(assigns) do
    ~H"""
    <.solid {assigns}>
      <path
        fill-rule="evenodd"
        d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
        clip-rule="evenodd"
      />
    </.solid>
    """
  end

  @doc """
  Heroicon name: solid/question-mark-circle
  """
  def solid_question_mark_circle(assigns) do
    ~H"""
    <.solid {assigns}>
      <path
        fill-rule="evenodd"
        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0 11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z"
        clip-rule="evenodd"
      />
    </.solid>
    """
  end

  @doc """
  Heroicon name: outline/x
  """
  def outline_x(assigns) do
    ~H"""
    <.outline {assigns}>
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
    </.outline>
    """
  end

  defp solid(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "h-5 w-5" end)
      |> assign(:extras, assigns_to_attributes(assigns, [:class]))

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      {@extras}
    >
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  defp outline(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "h-6 w-6" end)
      |> assign(:extras, assigns_to_attributes(assigns, [:class]))

    ~H"""
    <svg
      class="h-6 w-6"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="2"
      stroke="currentColor"
      {@extras}
    >
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end
end