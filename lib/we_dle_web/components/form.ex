defmodule WeDleWeb.Components.Form do
  @moduledoc """
  A collection of form components.
  """

  use WeDleWeb, :component

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
    <div x-data={"{value: #{@value}}"} class="ml-3 flex items-center h-5">
      <!-- Enabled: "bg-indigo-600", Not Enabled: "bg-gray-200" -->
      <button
        aria-checked={!(@value == 0)}
        type="input"
        name={"#{@form.id}[#{@field}]"}
        form={@form.id}
        phx-click={"change_#{@field}"}
        class={
          if(@value == 0, do: "bg-zinc-400", else: "bg-amber-600") <>
            " relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        }
      >
        <%= hidden_input(@form, @field) %>
        <span class="sr-only">Use setting</span>
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
end
