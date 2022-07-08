defmodule WeDleWeb.Components.Game do
  @moduledoc """
  Game UI components.
  """

  use WeDleWeb, :component

  def tile(assigns) do
    ~H"""
    <div class="w-[50px] h-[50px] border-2 border-solid border-zinc-500">
      <div class="grid place-items-center text-4xl">
        <%= @letter %>
      </div>
    </div>
    """
  end

  def board(assigns) do
    ~H"""
    <div class="h-full w-full" id="wordle-app-game">
      <div class="h-max w-max">
        <div class="Board-module_board__lbzlf" style="width: 350px; height: 420px;">
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
          <div class="Row-module_row__dEHfN">
            <div class="" style="animation-delay: 0ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 100ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 200ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 300ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
            <div class="" style="animation-delay: 400ms;">
              <div
                class="Tile-module_tile__3ayIZ"
                data-state="empty"
                data-animation="idle"
                data-testid="tile"
              >
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="Keyboard-module_keyboard__1HSnn">
        <div class="Keyboard-module_row__YWe5w">
          <button type="button" data-key="q" class="Key-module_key__Rv-Vp">q</button><button
            type="button"
            data-key="w"
            class="Key-module_key__Rv-Vp"
          >w</button><button type="button" data-key="e" class="Key-module_key__Rv-Vp">e</button><button
            type="button"
            data-key="r"
            class="Key-module_key__Rv-Vp"
          >r</button><button type="button" data-key="t" class="Key-module_key__Rv-Vp">t</button><button
            type="button"
            data-key="y"
            class="Key-module_key__Rv-Vp"
          >y</button><button type="button" data-key="u" class="Key-module_key__Rv-Vp">u</button><button
            type="button"
            data-key="i"
            class="Key-module_key__Rv-Vp"
          >i</button><button type="button" data-key="o" class="Key-module_key__Rv-Vp">o</button><button
            type="button"
            data-key="p"
            class="Key-module_key__Rv-Vp"
          >p</button>
        </div>
        <div class="Keyboard-module_row__YWe5w">
          <div data-testid="spacer" class="Key-module_half__ljsj8"></div>
          <button type="button" data-key="a" class="Key-module_key__Rv-Vp">a</button><button
            type="button"
            data-key="s"
            class="Key-module_key__Rv-Vp"
          >s</button><button type="button" data-key="d" class="Key-module_key__Rv-Vp">d</button><button
            type="button"
            data-key="f"
            class="Key-module_key__Rv-Vp"
          >f</button><button type="button" data-key="g" class="Key-module_key__Rv-Vp">g</button><button
            type="button"
            data-key="h"
            class="Key-module_key__Rv-Vp"
          >h</button><button type="button" data-key="j" class="Key-module_key__Rv-Vp">j</button><button
            type="button"
            data-key="k"
            class="Key-module_key__Rv-Vp"
          >k</button><button type="button" data-key="l" class="Key-module_key__Rv-Vp">l</button>
          <div data-testid="spacer" class="Key-module_half__ljsj8"></div>
        </div>
        <div class="Keyboard-module_row__YWe5w">
          <button
            type="button"
            data-key="↵"
            class="Key-module_key__Rv-Vp Key-module_oneAndAHalf__K6JBY"
          >
            enter
          </button>
          <button type="button" data-key="z" class="Key-module_key__Rv-Vp">z</button>
          <button type="button" data-key="x" class="Key-module_key__Rv-Vp">x</button><button
            type="button"
            data-key="c"
            class="Key-module_key__Rv-Vp"
          >c</button>
          <button type="button" data-key="v" class="Key-module_key__Rv-Vp">v</button>
          <button type="button" data-key="b" class="Key-module_key__Rv-Vp">b</button>
          <button type="button" data-key="n" class="Key-module_key__Rv-Vp">n</button>
          <button type="button" data-key="m" class="Key-module_key__Rv-Vp">m</button>
          <button
            type="button"
            data-key="←"
            class="Key-module_key__Rv-Vp Key-module_oneAndAHalf__K6JBY"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              height="24"
              viewBox="0 0 24 24"
              width="24"
              class="game-icon"
              data-testid="icon-backspace"
            >
              <path
                fill="var(--color-tone-1)"
                d="M22 3H7c-.69 0-1.23.35-1.59.88L0 12l5.41 8.11c.36.53.9.89 1.59.89h15c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H7.07L2.4 12l4.66-7H22v14zm-11.59-2L14 13.41 17.59 17 19 15.59 15.41 12 19 8.41 17.59 7 14 10.59 10.41 7 9 8.41 12.59 12 9 15.59z"
              >
              </path>
            </svg>
          </button>
        </div>
      </div>
      <div class="ToastContainer-module_toaster__QDad3" id="ToastContainer-module_gameToaster__yjzPn">
      </div>
      <div
        class="ToastContainer-module_toaster__QDad3"
        id="ToastContainer-module_systemToaster__fIZdf"
      >
      </div>
    </div>
    """
  end
end
