defmodule WeDleWeb.GameLive do
  @moduledoc """
  The live view that renders and controls the game.
  """

  use WeDleWeb, :live_view

  alias WeDle.Game

  @impl true
  def render(assigns) do
    ~H"""
    <.expire_button />
    <%= if connected?(@socket) do %>
      <Components.Game.game_board board={@player.board} />
    <% end %>
    """
  end

  def expire_button(assigns) do
    ~H"""
    <button
      type="button"
      class={
        "inline-flex justify-center items-center px-2.5 py-1.5 shadow-sm " <>
          "text-xs font-medium rounded text-zinc-100 bg-red-600 hover:bg-red-700 " <>
          "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-700"
      }
      phx-click="expire"
    >
      expire
    </button>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    game_id = Map.fetch!(session, "game_id")
    settings = Map.fetch!(session, "settings")
    connected = connected?(socket)

    {:ok,
     socket
     |> assign(:game_id, game_id)
     |> assign(Map.from_struct(settings))
     |> assign(:env, WeDle.config([:env]))
     |> join_game_if_connected(connected)}
  end

  defp join_game_if_connected(socket, true) do
    %{player_id: player_id, game_id: game_id} = socket.assigns

    {:ok, player} = WeDle.Game.start_or_join(game_id, player_id)

    assign(socket, :player, player)
  end

  defp join_game_if_connected(socket, false), do: socket

  @impl true
  def handle_event("change_" <> setting, _, %{assigns: assigns} = socket) do
    setting = String.to_existing_atom(setting)
    value = if Map.get(assigns, setting) == 0, do: 1, else: 0

    {:noreply, assign(socket, setting, value)}
  end

  def handle_event("expire", _, socket) do
    %{game_id: game_id} = socket.assigns
    :ok = WeDle.Game.force_expire(game_id)
    {:noreply, redirect(socket, to: Routes.game_path(socket, :game, game_id))}
  end

  def handle_event("key", %{"value" => "←"}, socket) do
    socket = clear_flash(socket)
    {:noreply, remove_last_value_from_board(socket)}
  end

  def handle_event("key", %{"value" => "↵"}, %{assigns: assigns} = socket) do
    socket = clear_flash(socket)

    %{game_id: game_id, player: %{board: board} = player} = assigns
    row = Enum.at(board.rows, board.turns)

    socket =
      if length(row) < board.word_length do
        put_flash(socket, :error, "not enough letters")
      else
        word = Enum.map_join(row, fn {_, char} -> char end)

        case Game.submit_word(game_id, player.id, word) do
          {:ok, player} -> assign(socket, :player, player)
          {:error, reason} -> put_flash(socket, :error, reason)
        end
      end

    {:noreply, socket}
  end

  def handle_event("key", %{"value" => value}, socket) do
    socket = clear_flash(socket)
    {:noreply, insert_value_in_board(socket, value)}
  end

  defp remove_last_value_from_board(%{assigns: assigns} = socket) do
    %{player: %{board: board} = player} = assigns
    row = board.rows |> Enum.at(board.turns) |> List.delete_at(-1)
    deep_update_row_in_assigns(socket, player, board, row)
  end

  defp insert_value_in_board(%{assigns: assigns} = socket, value) do
    %{player: %{board: board} = player} = assigns
    row = Enum.at(board.rows, board.turns)
    row = if length(row) == board.word_length, do: row, else: row ++ [{3, value}]
    deep_update_row_in_assigns(socket, player, board, row)
  end

  defp deep_update_row_in_assigns(socket, player, board, row) do
    rows = List.replace_at(board.rows, board.turns, row)
    board = %{board | rows: rows}
    player = %{player | board: board}
    assign(socket, :player, player)
  end
end
