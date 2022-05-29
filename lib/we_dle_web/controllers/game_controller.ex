defmodule WeDleWeb.GameController do
  @moduledoc """
  The controller that renders the `GameLive` live view.
  """

  use WeDleWeb, :controller

  alias WeDle.Game
  alias WeDleWeb.GameLive

  def index(conn, _params) do
    game_id = get_session(conn, :game_id)

    if game_id do
      redirect(conn, to: Routes.game_path(conn, :show, game_id))
    else
      live_render(conn, GameLive.Index)
    end
  end

  def show(conn, %{"game_id" => game_id}) do
    if Game.exists?(game_id) do
      conn
      |> put_session(:game_id, game_id)
      |> live_render(GameLive.Show)
    else
      conn
      |> delete_session(:game_id)
      |> redirect(to: Routes.game_path(conn, :index))
    end
  end
end
