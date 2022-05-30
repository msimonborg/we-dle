defmodule WeDleWeb.Admin.UserRegistrationControllerTest do
  use WeDleWeb.ConnCase, async: true

  import WeDle.AccountsFixtures

  describe "GET /admin/users/register" do
    test "renders registration page when logged in", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> get(Routes.admin_user_registration_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</h1>"
    end

    test "redirects if not logged in", %{conn: conn} do
      conn = get(conn, Routes.admin_user_registration_path(conn, :new))
      assert redirected_to(conn) == Routes.admin_user_session_path(conn, :new)
    end
  end

  describe "POST /admin/users/register" do
    @tag :capture_log
    test "creates account and rerenders the new page", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> log_in_user(user_fixture())
        |> post(Routes.admin_user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(email: email)
        })

      assert html_response(conn, 200) =~ "Register</h1>"

      conn =
        conn
        |> delete(Routes.admin_user_session_path(conn, :delete))
        |> post(Routes.admin_user_session_path(conn, :create), %{
          "user" => %{"email" => email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "render errors for invalid data", %{conn: conn} do
      response =
        conn
        |> log_in_user(user_fixture())
        |> post(Routes.admin_user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })
        |> html_response(200)

      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
