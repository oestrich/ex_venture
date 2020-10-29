defmodule Web.Router do
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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :index

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

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
