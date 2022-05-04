defmodule WeDleWeb.PageController do
  use WeDleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
