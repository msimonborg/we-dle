defmodule WeDleWeb.GameLiveTest do
  use WeDleWeb.ConnCase
  import Phoenix.LiveViewTest
  alias WeDle.Game

  describe "GameLive" do
    test "redirects to the index page when the game_id doesn't exist", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/game_id")
    end

    test "renders the show page when the game_id exists", %{conn: conn} do
      id = Game.unique_id()
      Game.start(id)
      {:ok, _, html} = live(conn, "/" <> id)
      assert html =~ "expire"
    end

    test "clicking \"expire\" ends the game and redirects to Index", %{conn: conn} do
      id = Game.unique_id()
      Game.start(id)
      {:ok, view, _} = live(conn, "/" <> id)

      assert {:ok, conn} =
               view
               |> element("button", "expire")
               |> render_click()
               |> follow_redirect(conn)

      assert redirected_to(conn) == "/"

      refute Game.exists?(id)
    end

    test "clicking the dark mode toggle switch changes themes", %{conn: conn} do
      id = Game.unique_id()
      Game.start(id)
      {:ok, view, html} = live(conn, "/" <> id)

      assert html =~ ~s{<main class="light"}

      assert view
             |> element(~s{[phx-click="change_dark_theme"]})
             |> render_click() =~ ~s{<main class="dark"}
    end
  end
end
