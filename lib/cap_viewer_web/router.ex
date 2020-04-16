defmodule CapViewerWeb.Router do
  use CapViewerWeb, :router
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {CapViewerWeb.LayoutView, :root}
    plug :put_layout, {CapViewerWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CapViewerWeb do
    pipe_through :browser

    live "/entries", EntriesLive
    get "/", PageController, :index
    live_dashboard "/dashboard"
  end

  # Other scopes may use custom stacks.
  # scope "/api", CapViewerWeb do
  #   pipe_through :api
  # end
end
