defmodule WeDleWeb.Components.Form do
  @moduledoc """
  A collection of form components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def toggle_input(assigns) do
    unless assigns[:form] do
      raise "expected :form assign for menu button component"
    end

    unless assigns[:field] do
      raise "expected :field assign for menu button component"
    end

    unless assigns[:label] do
      raise "expected :label assign for menu button component"
    end

    unless assigns[:value] do
      raise "expected :value assign for menu button component"
    end

    unless assigns[:dark_theme] do
      raise "expected :dark_theme assign for menu button component"
    end

    ~H"""
    <div x-data={"{value: #{@value}}"} class="relative flex items-start py-6">
      <div class={"min-w-0 flex-1 #{text_color(@dark_theme)} text-sm font-medium text-lg"}>
        <%= label(@form, @field, @label) %>
      </div>
      <div class="ml-3 flex items-center h-5">
        <!-- Enabled: "bg-indigo-600", Not Enabled: "bg-gray-200" -->
        <input
          type="hidden"
          id={"#{@form.id}_#{@field}"}
          name={"#{@form.id}[#{@field}]"}
          :value="value"
        />
        <button
          @click="value = (value == 0 ? 1 : 0)"
          :class="value == 0 ? 'bg-zinc-400' : 'bg-amber-600'"
          :aria-checked="!(value == 0)"
          name={@field}
          form={@form.id}
          type="input"
          class="relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          role="switch"
        >
          <span class="sr-only">Use setting</span>
          <!-- Enabled: "translate-x-5", Not Enabled: "translate-x-0" -->
          <span
            aria-hidden="true"
            :class="value == 0 ? 'translate-x-0' : 'translate-x-5'"
            class="pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200"
          >
          </span>
        </button>
      </div>
    </div>
    """
  end
end
