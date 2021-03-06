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
  Heroicon name: solid/x
  """
  def solid_x(assigns) do
    ~H"""
    <.solid {assigns}>
      <path
        fill-rule="evenodd"
        d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
        clip-rule="evenodd"
      />
    </.solid>
    """
  end

  @doc """
  Heroicon name: outline/exclamation
  """
  def outline_exclamation(assigns) do
    ~H"""
    <.outline {assigns}>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
      />
    </.outline>
    """
  end

  @doc """
  Heroicon name: outline/check-circle
  """
  def outline_check_circle(assigns) do
    ~H"""
    <.outline {assigns}>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </.outline>
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

  @doc """
  Heroicon name: outline/backspace
  """
  def outline_backspace(assigns) do
    ~H"""
    <.outline {assigns}>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 12l6.414 6.414a2 2 0 001.414.586H19a2 2 0 002-2V7a2 2 0 00-2-2h-8.172a2 2 0 00-1.414.586L3 12z"
      />
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
      class={@class}
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
