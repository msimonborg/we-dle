defmodule WeDleWeb.IframeController do
  @moduledoc """
  This route exists to provide a destination for hidden iframes in live views.

  Hidden iframes provide a target for performing form submissions and other
  HTTP requests that might mutate session data, without having to naviagate
  away from the live view.
  """

  use WeDleWeb, :controller

  def index(conn, _) do
    html(conn, "ok")
  end
end
