defmodule CapViewerWeb.PageController do
  use CapViewerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
