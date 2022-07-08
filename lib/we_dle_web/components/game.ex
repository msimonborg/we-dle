defmodule WeDleWeb.Components.Game do
  @moduledoc """
  Game UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def board(assigns) do
    ~H"""
    <div class="h-full flex grid place-content-center" id="board">
      <div class="initial h-[428px] w-[356px]">
        <div class="h-full grid grid-rows-6 gap-1">
          <%= for row <- @board.rows do %>
            <.row letters={row} word_length={@board.word_length} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def row(assigns) do
    assigns =
      if length(assigns.letters) == assigns.word_length do
        assigns
      else
        assign(assigns, :letters, Enum.map(1..assigns.word_length, fn _ -> {3, ""} end))
      end

    ~H"""
    <div class="grid grid-cols-5 gap-1">
      <%= for {distance, letter} <- @letters do %>
        <.tile distance={distance} letter={letter} />
      <% end %>
    </div>
    """
  end

  def tile(assigns) do
    ~H"""
    <div class={"h-auto w-auto border-2 border-solid #{border_color()}"}>
      <div class={"h-full grid place-items-center text-4xl #{text_color()}"}>
        <%= @letter %>
      </div>
    </div>
    """
  end
end
