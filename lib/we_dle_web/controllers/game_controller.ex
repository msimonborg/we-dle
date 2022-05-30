defmodule WeDleWeb.GameController do
  @moduledoc """
  The controller that renders the `GameLive` live view.
  """

  use WeDleWeb, :controller

  alias WeDle.Game
  alias WeDleWeb.GameLive

  plug :remove_app_layout

  def index(conn, _params) do
    game_id = get_session(conn, :game_id)

    if game_id do
      redirect(conn, to: Routes.game_path(conn, :show, game_id))
    else
      live_render(conn, GameLive.Index, session: %{"current_user" => conn.assigns[:current_user]})
    end
  end

  def show(conn, %{"game_id" => game_id}) do
    if Game.exists?(game_id) do
      conn
      |> put_session(:game_id, game_id)
      |> live_render(GameLive.Show, session: %{"current_user" => conn.assigns[:current_user]})
    else
      conn
      |> delete_session(:game_id)
      |> redirect(to: Routes.game_path(conn, :index))
    end
  end

  defp remove_app_layout(conn, _), do: put_layout(conn, false)
end
