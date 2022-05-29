defmodule WeDleWeb.GameControllerTest do
  use WeDleWeb.ConnCase
  alias WeDle.Game

  setup %{conn: conn} do
    {:ok, conn: Phoenix.ConnTest.init_test_session(conn, %{})}
  end

  describe "index" do
    test "renders with status OK", %{conn: conn} do
      assert conn
             |> get("/")
             |> html_response(200) =~ "we-dle"
    end

    test "redirects to :show action when a game ID is found in session", %{conn: conn} do
      id = Game.unique_id()

      assert conn
             |> put_session(:game_id, id)
             |> get("/")
             |> redirected_to() == Routes.game_path(conn, :show, id)
    end
  end

  describe "show" do
    test "renders with status OK and adds game ID to the session if it exists", %{conn: conn} do
      id = Game.unique_id()
      {:ok, _} = Game.start_or_join(id, "p1")

      conn = get(conn, Routes.game_path(conn, :show, id))

      assert html_response(conn, 200) =~ "we-dle"
      assert get_session(conn, :game_id) == id
    end

    test "redirects to index and deletes from session if the game ID doesn't exist", %{conn: conn} do
      id = Game.unique_id()

      conn = get(conn, Routes.game_path(conn, :show, id))

      assert redirected_to(conn) == Routes.game_path(conn, :index)
      assert get_session(conn, :game_id) |> is_nil()
    end
  end
end
