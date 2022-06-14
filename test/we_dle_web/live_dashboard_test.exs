defmodule WeDleWeb.LiveDashboardTest do
  use WeDleWeb.ConnCase, async: true
  import Plug.BasicAuth, only: [encode_basic_auth: 2]

  @username Application.compile_env(:we_dle, :basic_auth)[:username]
  @password Application.compile_env(:we_dle, :basic_auth)[:password]

  test "returns a 401 status when not authenticated", %{conn: conn} do
    assert conn
           |> get(Routes.live_dashboard_path(conn, :home))
           |> response(401) =~ "Unauthorized"
  end

  test "returns the live dashboard home page when authenticated", %{conn: conn} do
    conn = put_req_header(conn, "authorization", encode_basic_auth(@username, @password))

    assert conn
           |> get(Routes.live_dashboard_path(conn, :home))
           |> redirected_to(302) =~ "/dashboard/home"

    assert conn
           |> get("/dashboard/home")
           |> html_response(200) =~ "Phoenix LiveDashboard"
  end
end
