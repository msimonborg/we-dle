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
    settings = Settings.new(dark_theme: 1)
    params = %{"settings" => Map.from_struct(settings)}

    conn =
      conn
      |> put(Routes.settings_path(conn, :update), params)
      |> fetch_cookies(signed: [@cookie])
      |> fetch_session()

    assert html_response(conn, 200) =~ "ok"
    assert conn.cookies[@cookie] == settings
    assert get_session(conn, "settings") == settings
  end

  test "will not store settings when they are invalid", %{conn: conn} do
    settings = Settings.new(dark_theme: true)
    params = %{"settings" => Map.from_struct(settings)}

    conn =
      conn
      |> put(Routes.settings_path(conn, :update), params)
      |> fetch_cookies(signed: [@cookie])
      |> fetch_session()

    assert html_response(conn, 422) =~ "errors"
    assert conn.cookies[@cookie] != settings
    assert get_session(conn, "settings") != settings
  end
end
