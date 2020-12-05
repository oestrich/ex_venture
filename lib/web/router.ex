defmodule Web.Router do
  @moduledoc false

  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Web.Plugs.FetchUser
  end

  pipeline :logged_in do
    plug Web.Plugs.EnsureUser
  end

  pipeline :admin do
    plug :put_layout, {Web.LayoutView, "admin.html"}
    plug Web.Plugs.EnsureAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :index

    get("/client*page", PageController, :client)

    get("/sign-in", SessionController, :new)

    post("/sign-in", SessionController, :create)

    delete("/sign-out", SessionController, :delete)

    get("/register", RegistrationController, :new)

    post("/register", RegistrationController, :create)

    get("/register/reset", RegistrationResetController, :new)

    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)

    post("/register/reset/verify", RegistrationResetController, :update)

    get("/users/confirm", ConfirmationController, :confirm)
  end

  scope "/", Web do
    pipe_through([:browser, :logged_in])

    resources("/profile", ProfileController, singleton: true, only: [:show, :edit, :update])
  end

  scope "/admin", Web.Admin, as: :admin do
    pipe_through([:browser, :logged_in, :admin])

    get("/", DashboardController, :index)

    post("/staged-changes/commit", StagedChangesController, :commit)

    resources("/rooms", RoomController, only: [:index, :show, :edit, :update])

    post("/rooms/:id/publish", RoomController, :publish, as: :room)

    delete("/rooms/:id/changes", RoomController, :delete_changes, as: :room_changes)

    resources("/staged-changes", StagedChangesController, only: [:index, :delete])

    resources("/users", UserController, only: [:index, :show])

    resources("/zones", ZoneController, except: [:delete]) do
      resources("/rooms", RoomController, only: [:new, :create])
    end

    post("/zones/:id/publish", ZoneController, :publish, as: :zone)

    delete("/zones/:id/changes", ZoneController, :delete_changes, as: :zone_changes)
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
