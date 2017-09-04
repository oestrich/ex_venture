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

    get "/play", PlayController, :show

    get "/who", PageController, :who
  end

  scope "/admin", Web.Admin do
    pipe_through :browser

    get "/", DashboardController, :index

    resources "/classes", ClassController, only: [:index, :show, :new, :create, :edit, :update] do
      resources "/skills", SkillController, only: [:new, :create]
    end

    resources "/config", ConfigController, only: [:index]

    resources "/exits", RoomExitController, only: [:delete], as: :exit

    resources "/insights", InsightController, only: [:index]

    resources "/items", ItemController, only: [:index, :show, :edit, :update, :new, :create]

    resources "/npcs", NPCController, only: [:index, :show, :edit, :update, :new, :create] do
      resources "/spawners", NPCSpawnerController, only: [:new, :create], as: :spawner
    end

    resources "/npc_spawners", NPCSpawnerController, only: [:edit, :update, :delete]

    resources "/room_items", RoomItemController, only: [:delete]

    resources "/rooms", RoomController, only: [:show, :edit, :update] do
      resources "/exits", RoomExitController, only: [:new, :create], as: :exit

      resources "/items", RoomItemController, only: [:new, :create]
    end

    resources "/sessions", SessionController, only: [:new, :create]

    resources "/skills", SkillController, only: [:show, :edit, :update]

    resources "/users", UserController, only: [:index, :show]

    resources "/zones", ZoneController, only: [:index, :show, :new, :create, :edit, :update] do
      resources "/rooms", RoomController, only: [:new, :create]
    end
  end
end
