defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/admin", Web.Admin do
    pipe_through :browser

    get "/", DashboardController, :index

    resources "/items", ItemController, only: [:index, :show, :edit, :update, :new, :create]

    resources "/rooms", RoomController, only: [:show]

    resources "/sessions", SessionController, only: [:new, :create]

    resources "/zones", ZoneController, only: [:index, :show, :new, :create]
  end
end
