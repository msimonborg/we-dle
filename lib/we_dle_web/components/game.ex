defmodule WeDleWeb.Components.Game do
  @moduledoc """
  Game UI components.
  """

  use WeDleWeb, :component

  import WeDleWeb.LiveHelpers

  def game_board(assigns) do
    ~H"""
    <div class="flex grow justify-center items-center overflow-hidden" id="board">
      <div class="grid grid-rows-6 gap-[5px] p-[10px] h-full max-h-[420px] max-w-[350px] aspect-[35/42] box-border">
        <%= for row <- @board.rows do %>
          <.game_board_row letters={row} word_length={@board.word_length} />
        <% end %>
      </div>
    </div>
    <.keyboard />
    """
  end

  def game_board_row(%{letters: letters, word_length: word_length} = assigns) do
    difference = word_length - length(letters)

    assigns =
      if difference == 0 do
        assigns
      else
        assign(assigns, :letters, letters ++ Enum.map(1..difference, fn _ -> {3, ""} end))
      end

    ~H"""
    <div class="grid grid-cols-5 gap-[5px]">
      <%= for {distance, letter} <- @letters do %>
        <.game_board_tile distance={distance} letter={letter} />
      <% end %>
    </div>
    """
  end

  def game_board_tile(%{distance: distance} = assigns) do
    background_color =
      case distance do
        0 -> "green-500"
        1 -> "yellow-500"
        2 -> "zinc-500"
        3 -> background_color()
      end

    assigns = assign(assigns, :background_color, background_color)

    ~H"""
    <div class={
      "w-full inline-flex justify-center items-center text-[2rem] leading-8 " <>
        "font-bold align-middle box-border uppercase border-2 border-solid " <>
        "#{border_color()} #{text_color()} bg-#{@background_color}"
    }>
      <%= @letter %>
    </div>
    """
  end

  def keyboard(assigns) do
    ~H"""
    <div class="my-0 mx-[8px] select-none">
      <.keyboard_row keys={~w(q w e r t y u i o p)} />

      <.keyboard_row keys={~w(a s d f g h j k l)}>
        <:left_extra><.keyboard_spacer /></:left_extra>
        <:right_extra><.keyboard_spacer /></:right_extra>
      </.keyboard_row>

      <.keyboard_row keys={~w(z x c v b n m)}>
        <:left_extra>
          <.key value="???" class="grow-[1.5] text-xs">
            enter
          </.key>
        </:left_extra>
        <:right_extra>
          <.key value="???" class="grow-[1.5] text-xs">
            <Components.Icons.outline_backspace />
          </.key>
        </:right_extra>
      </.keyboard_row>
    </div>
    """
  end

  def keyboard_row(assigns) do
    ~H"""
    <div class="flex w-full mt-0 mb-[8px] mx-auto touch-manipulation space-x-1.5">
      <%= if assigns[:left_extra] do %>
        <%= render_slot(@left_extra) %>
      <% end %>

      <%= for key <- @keys do %>
        <.key value={key}><%= key %></.key>
      <% end %>

      <%= if assigns[:right_extra] do %>
        <%= render_slot(@right_extra) %>
      <% end %>
    </div>
    """
  end

  def key(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <button
      type="button"
      value={@value}
      phx-click="key"
      class={
        [
          "font-bold border-0 p-0 h-[58px] rounded cursor-pointer ",
          "select-none flex flex-1 justify-center items-center uppercase ",
          "bg-zinc-300 dark:bg-zinc-600 #{text_color()}",
          @class
        ]
      }
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def keyboard_spacer(assigns) do
    ~H"""
    <div class="grow-[0.5]"></div>
    """
  end
end
