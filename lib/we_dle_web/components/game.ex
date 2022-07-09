defmodule WeDleWeb.Components.Game do
  @moduledoc """
  Game UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def board(assigns) do
    ~H"""
    <div class="flex grow justify-center items-center overflow-hidden" id="board">
      <div class="grid grid-rows-6 gap-[5px] p-[10px] h-[420px] w-[350px] box-border">
        <%= for row <- @board.rows do %>
          <.row letters={row} word_length={@board.word_length} />
        <% end %>
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
    <div class="grid grid-cols-5 gap-[5px]">
      <%= for {distance, letter} <- @letters do %>
        <.tile distance={distance} letter={letter} />
      <% end %>
    </div>
    """
  end

  def tile(assigns) do
    ~H"""
    <div class={
      "w-full inline-flex justify-center items-center text-[2rem] leading-8 " <>
        "font-bold align-middle box-border uppercase border-2 border-solid " <>
        "#{border_color()} #{text_color()}"
    }>
      <%= @letter %>
    </div>
    """
  end
end
