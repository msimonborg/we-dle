defmodule WeDleWeb.GameController do
  @moduledoc """
  Plugs that handle redirection to existing games, or away from
  expired ones.
  """

  use WeDleWeb, :controller

  alias WeDle.Game
  alias WeDleWeb.{GameLive, LobbyLive}

  plug :remove_app_layout

  def lobby(conn, _params) do
    game_id = get_session(conn, :game_id)
    game_mode = get_session(conn, :game_mode)

    if game_id && game_mode do
      redirect(conn, to: Routes.game_path(conn, :game, game_id, %{game_mode: game_mode}))
    else
      live_render(conn, LobbyLive)
    end
  end

  def game(conn, %{"game_id" => game_id, "game_mode" => game_mode}) do
    if Game.exists?(game_id) do
      conn
      |> put_session(:game_id, game_id)
      |> put_session(:game_mode, game_mode)
      |> live_render(GameLive)
    else
      conn
      |> delete_session(:game_id)
      |> delete_session(:game_mode)
      |> redirect(to: Routes.game_path(conn, :lobby))
    end
  end

  def game(conn, _), do: redirect(conn, to: Routes.game_path(conn, :lobby))

  defp remove_app_layout(conn, _), do: put_layout(conn, false)
end
