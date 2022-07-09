defmodule WeDleWeb.Components.Flash do
  @moduledoc """
  Flash messages
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  @doc """
  Renders a message.
  """
  def message(assigns) do
    assigns = assign_flash_icon(assigns)

    ~H"""
    <div
      aria-live="assertive"
      class="z-50 fixed inset-0 flex px-4 py-6 pointer-events-none sm:p-6 items-start"
      id="flash-message"
      x-data="{ message: false }"
      x-init="setTimeout(function() {message = ! message}, 1); setTimeout(function() {message = ! message}, 5000)"
    >
      <div x-cloak class="w-full flex flex-col items-center space-y-4 sm:items-end">
        <div
          x-show="message"
          x-transition:enter="transform ease-out duration-300 transition"
          x-transition:enter-start="translate-y-0 translate-x-8"
          x-transition:enter-end="translate-y-0 opacity-100 translate-x-0"
          x-transition:leave="transition ease-in duration-100"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
          class={
            "max-w-sm w-full #{background_color()} border-2 #{border_color()} shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden"
          }
        >
          <div class="p-4">
            <div class="flex items-start">
              <div class="flex-shrink-0">
                <%= @icon %>
              </div>
              <div class="ml-3 w-0 flex-1 pt-0.5">
                <p class={"text-sm font-medium #{text_color()}"}>
                  <%= if @level == "info", do: "Success!", else: "Oops!" %>
                </p>
                <p class={"mt-1 text-sm #{text_color()}"}><%= @message %></p>
              </div>
              <div class="ml-4 flex-shrink-0 flex">
                <button
                  @click="message = ! message"
                  class={
                    "#{background_color()} rounded-md inline-flex #{text_color()} #{hover_text_color()} focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  }
                >
                  <span class="sr-only">Close</span>
                  <Components.Icons.solid_x aria-hidden="true" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp assign_flash_icon(%{level: "info"} = assigns) do
    icon = ~H"""
    <Components.Icons.outline_check_circle aria-hidden="true" class="h-6 w-6 text-green-400" />
    """

    assign(assigns, :icon, icon)
  end

  defp assign_flash_icon(%{level: "error"} = assigns) do
    icon = ~H"""
    <Components.Icons.outline_exclamation aria-hidden="true" class="h-6 w-6 text-red-500" />
    """

    assign(assigns, :icon, icon)
  end
end
