defmodule WeDleWeb.GameControllerTest do
  use WeDleWeb.ConnCase
  alias WeDle.Game

  setup %{conn: conn} do
    {:ok, conn: Phoenix.ConnTest.init_test_session(conn, %{})}
  end

  describe "/" do
    test "renders with status OK", %{conn: conn} do
      assert conn
             |> get("/")
             |> html_response(200) =~ "We-dle"
    end

    test "redirects to game when a game ID and mode are found in session", %{conn: conn} do
      id = Game.unique_id()

      assert conn
             |> put_session(:game_id, id)
             |> put_session(:game_mode, "mode")
             |> get("/")
             |> redirected_to() == Routes.game_path(conn, :game, id, %{game_mode: "mode"})
    end
  end

  describe "/:game_id?game_mode=game_mode" do
    test "renders with status OK and adds game ID/mode to the session if it exists", %{conn: conn} do
      id = Game.unique_id()
      {:ok, _} = Game.start_or_join(id, "p1")

      conn = get(conn, Routes.game_path(conn, :game, id, %{game_mode: "mode"}))

      assert html_response(conn, 200) =~ "We-dle"
      assert get_session(conn, :game_id) == id
      assert get_session(conn, :game_mode) == "mode"
    end

    test "redirects to lobby and deletes from session if the game ID doesn't exist", %{conn: conn} do
      id = Game.unique_id()

      conn =
        conn
        |> put_session(:game_id, id)
        |> put_session(:game_mode, "mode")
        |> get(Routes.game_path(conn, :game, id, %{game_mode: "mode"}))

      assert redirected_to(conn) == Routes.game_path(conn, :lobby)
      assert get_session(conn, :game_id) |> is_nil()
      assert get_session(conn, :game_mode) |> is_nil()
    end
  end
end
