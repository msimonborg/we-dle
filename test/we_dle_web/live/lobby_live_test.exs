defmodule WeDleWeb.LobbyLiveTest do
  use WeDleWeb.ConnCase
  import Phoenix.LiveViewTest
  alias WeDle.Game

  describe "LobbyLive" do
    test "renders the index page", %{conn: conn} do
      {:ok, _, html} = live(conn, "/")
      assert html =~ "start game"
    end

    test "clicking \"start game\" starts a game and redirects to Show", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      assert {:error, {:redirect, %{to: "/" <> game_id_and_mode}}} =
               view
               |> form("#game-select", %{"game_select" => "Classic"})
               |> render_submit()

      game_id = String.trim(game_id_and_mode, "?game_mode=Classic")

      assert Game.exists?(game_id)
    end

    test "clicking the dark mode toggle switch changes themes", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      assert html =~ ~s{<main class="light"}

      assert view
             |> element(~s{[phx-click="change_dark_theme"]})
             |> render_click() =~ ~s{<main class="dark"}
    end
  end
end
