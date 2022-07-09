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

    if game_id do
      redirect(conn, to: Routes.game_path(conn, :game, game_id))
    else
      live_render(conn, LobbyLive)
    end
  end

  def game(conn, %{"game_id" => game_id}) do
    if Game.exists?(game_id) do
      conn
      |> put_session(:game_id, game_id)
      |> live_render(GameLive)
    else
      conn
      |> delete_session(:game_id)
      |> redirect(to: Routes.game_path(conn, :lobby))
    end
  end

  defp remove_app_layout(conn, _), do: put_layout(conn, false)
end
