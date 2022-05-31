defmodule WeDleWeb.SettingsControllerTest do
  use WeDleWeb.ConnCase, async: true

  alias WeDleWeb.Settings

  @cookie WeDleWeb.SettingsController.cookie()

  setup %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Map.put(:secret_key_base, "testing123")

    {:ok, conn: conn}
  end

  test "stores valid settings as a Settings struct in the session", %{conn: conn} do
    return_to = "/"
    settings = Settings.new(theme: "dark")
    params = %{settings: Map.from_struct(settings), return_to: return_to}

    conn =
      conn
      |> post(Routes.settings_path(conn, :index), params)
      |> fetch_cookies(signed: [@cookie])
      |> fetch_session()

    assert redirected_to(conn) == "/"
    assert conn.cookies[@cookie] == settings
    assert get_session(conn, "settings") == settings
  end

  test "will not store settings when they are invalid", %{conn: conn} do
    return_to = "/"
    settings = Settings.new(theme: "burgundy")
    params = %{settings: Map.from_struct(settings), return_to: return_to}

    conn =
      conn
      |> post(Routes.settings_path(conn, :index), params)
      |> fetch_cookies(signed: [@cookie])
      |> fetch_session()

    assert redirected_to(conn) == "/"
    assert conn.cookies[@cookie] != settings
    assert get_session(conn, "settings") != settings
  end
end
