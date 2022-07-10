defmodule WeDleWeb.LobbyLive do
  @moduledoc """
  The live view that renders the welcome and game creation page.
  """

  use WeDleWeb, :live_view

  import WeDleWeb.LiveHelpers

  alias WeDle.Game

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <.game_select_form />
    """
  end

  def game_select_form(assigns) do
    ~H"""
    <!-- This example requires Tailwind CSS v2.0+ -->
    <.form
      let={f}
      for={:game_select}
      id="game-select"
      class={"m-auto w-80 font-mono tracking-wider uppercase #{text_color()}"}
      phx-submit="game_select"
    >
      <.game_select_title />
      <.game_select_card_set form={f} />
      <.game_select_submit />
    </.form>
    """
  end

  def game_select_title(assigns) do
    ~H"""
    <div class="m-4">
      <h2 class="text-2xl text-center">
        Welcome to <span class="normal-case tracking-normal font-serif">We-dle</span>!
      </h2>
      <p class="text-center">Please select a game mode:</p>
    </div>
    """
  end

  def game_select_card_set(assigns) do
    ~H"""
    <fieldset form="game-select">
      <legend class="sr-only">Game select options</legend>
      <div x-data="{ selected: undefined }" class="space-y-4">
        <.game_select_card form={@form} mode="Classic" default={true}>
          Play today's* Wordle against a friend
        </.game_select_card>
        <.game_select_card form={@form} mode="Any Wordle">
          Challenge each other with any word from the Wordle list
        </.game_select_card>
        <.game_select_card form={@form} mode="Freestyle" enabled={false}>
          Free-form challenge between 3 and 10 characters
        </.game_select_card>
      </div>
    </fieldset>
    """
  end

  def game_select_card(assigns) do
    assigns =
      assigns
      |> assign_new(:enabled, fn -> true end)
      |> assign_new(:default, fn -> false end)

    ~H"""
    <div>
      <label
        @click={"if (#{@enabled}) { selected = '#{@mode}' }"}
        :class={"selected == '#{@mode}' && 'ring-2 ring-zinc-500'"}
        x-init={"if (#{@default}) { selected = '#{@mode}' }"}
        class={
          "relative block #{background_color()} #{text_color()} border-2 #{border_color()} " <>
            "rounded-lg px-6 py-4 cursor-pointer flex justify-between justify-between h-32"
        }
      >
        <input
          type="radio"
          name="game_select"
          value={@mode}
          class="sr-only"
          aria-labelledby={"#{@mode}-label"}
          aria-describedby={"#{@mode}-description"}
          :aria-selected={"selected == '#{@mode}'"}
          :checked={"selected == '#{@mode}'"}
        />
        <span class="flex items-center">
          <span class="text-sm flex flex-col" :class={"#{@enabled} || 'text-zinc-500'"}>
            <span id={"#{@mode}-label"} class="text-xl font-medium">
              <%= @mode %>
              <%= unless @enabled do %>
                <span class="text-xs">* coming soon *</span>
              <% end %>
            </span>
            <span id={"#{@mode}-description"} class="block">
              <%= render_slot(@inner_block) %>
            </span>
          </span>
        </span>
      </label>
    </div>
    """
  end

  def game_select_submit(assigns) do
    ~H"""
    <%= submit("start game",
      class:
        "mt-4 block uppercase w-full py-2 items-center rounded-lg border-4 " <>
          "#{border_color()} focus:ring-2 focus:ring-zinc-500"
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    settings = Map.fetch!(session, "settings")

    {:ok,
     socket
     |> assign(:env, WeDle.config([:env]))
     |> assign(Map.from_struct(settings))}
  end

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end

  def handle_event("game_select", %{"game_select" => game_mode} = params, socket) do
    game_id = Game.unique_id()

    case Game.start(game_id) do
      {:ok, _} ->
        query_params = %{game_mode: game_mode}
        path = Routes.game_path(socket, :game, game_id, query_params)

        {:noreply, redirect(socket, to: path)}

      {:error, {:already_started, _}} ->
        # In the very unlikely event that the id is taken, log it and try again
        Logger.error("game ID \"#{game_id}\" is taken, generating a new one")
        handle_event("game_select", params, socket)
    end
  end
end
