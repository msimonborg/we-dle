defmodule WeDleWeb.PlayerAuth do
  @moduledoc """
  Functions to authenticate and store player data in browser cookies.
  """

  import Plug.Conn

  alias WeDle.Game

  # Make the remember me cookie valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @cookie "_we_dle_web_player_id"
  @cookie_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def fetch_or_store_player(conn, _opts) do
    conn = fetch_cookies(conn, signed: [@cookie])

    player_id =
      case conn.cookies[@cookie] do
        nil -> Game.unique_id()
        player_id when is_binary(player_id) -> player_id
      end

    conn
    |> put_resp_cookie(@cookie, player_id, @cookie_options)
    |> put_session(:player_id, player_id)
  end
end
