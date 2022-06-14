defmodule WeDleWeb.Router do
  use WeDleWeb, :router

  import Phoenix.LiveDashboard.Router
  import WeDleWeb.SettingsController

  defp basic_auth(conn, _) do
    username = Application.get_env(:we_dle, :basic_auth)[:username]
    password = Application.get_env(:we_dle, :basic_auth)[:password]
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WeDleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_or_store_settings
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", WeDleWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  scope "/" do
    pipe_through [:browser, :basic_auth]

    live_dashboard "/dashboard", metrics: WeDleWeb.Telemetry
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  # if Mix.env() == :dev do
  #   scope "/dev" do
  #     pipe_through :browser

  #     forward "/mailbox", Plug.Swoosh.MailboxPreview
  #   end
  # end

  scope "/", WeDleWeb do
    pipe_through :browser

    get "/iframe", IframeController, :index
    put "/settings", SettingsController, :update

    get "/", GameController, :index
    # This route must go last or /:game_id always matches any single-nested path
    get "/:game_id", GameController, :show
  end
end
