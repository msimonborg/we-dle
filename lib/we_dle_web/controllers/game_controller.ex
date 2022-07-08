defmodule WeDleWeb.GameController do
  @moduledoc """
  Plugs that handle redirection to existing games, or away from
  expired ones.
  """

  use WeDleWeb, :controller

  alias WeDle.Game
  alias WeDleWeb.AppLive

  def redirect_to_existing_game(conn, _) do
    current_path = current_path(conn)
    check_for_game_and_maybe_redirect(conn, current_path)
  end

  defp check_for_game_and_maybe_redirect(conn, "/") do
    game_id = get_session(conn, :game_id)

    if game_id do
      conn
      |> redirect(to: Routes.live_path(conn, AppLive.Game, game_id))
      |> halt()
    else
      conn
    end
  end

  defp check_for_game_and_maybe_redirect(conn, "/" <> game_id) do
    if Game.exists?(game_id) do
      put_session(conn, :game_id, game_id)
    else
      conn
      |> delete_session(:game_id)
      |> redirect(to: Routes.live_path(conn, AppLive.Lobby))
      |> halt()
    end
  end
end
