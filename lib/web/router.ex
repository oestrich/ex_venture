defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :public do
    plug Web.Plug.LoadUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web, as: :public do
    pipe_through [:browser, :public]

    get "/", PageController, :index

    get "/account", AccountController, :show
    put "/account", AccountController, :update

    resources "/classes", ClassController, only: [:index, :show]

    get "/help/commands", HelpController, :commands
    get "/help/commands/:command", HelpController, :command
    resources "/help", HelpController, only: [:index, :show]

    get "/play", PlayController, :show

    resources "/races", RaceController, only: [:index, :show]

    resources "/register", RegistrationController, only: [:new, :create]

    delete "/sessions", SessionController, :delete
    resources "/sessions", SessionController, only: [:new, :create]

    get "/who", PageController, :who
  end

  scope "/admin", Web.Admin do
    pipe_through :browser

    get "/", DashboardController, :index

    resources "/bugs", BugController, only: [:index, :show]

    resources "/classes", ClassController, only: [:index, :show, :new, :create, :edit, :update] do
      resources "/skills", SkillController, only: [:new, :create]
    end

    resources "/config", ConfigController, only: [:index]

    resources "/exits", RoomExitController, only: [:delete], as: :exit

    resources "/help_topics", HelpTopicController, only: [:index, :show, :new, :create, :edit, :update]

    resources "/insights", InsightController, only: [:index]

    resources "/items", ItemController, only: [:index, :show, :edit, :update, :new, :create] do
      resources "/tags", ItemTaggingController, only: [:new, :create], as: :tagging
    end

    resources "/item_tags", ItemTagController, only: [:index, :show, :edit, :update, :new, :create]

    resources "/item_taggings", ItemTaggingController, only: [:delete]

    resources "/npcs", NPCController, only: [:index, :show, :edit, :update, :new, :create] do
      resources "/items", NPCItemController, only: [:new, :create, :delete], as: :item

      resources "/spawners", NPCSpawnerController, only: [:new, :create], as: :spawner
    end

    resources "/npc_spawners", NPCSpawnerController, only: [:show, :edit, :update, :delete]

    resources "/races", RaceController, only: [:index, :show, :new, :create, :edit, :update]

    resources "/room_items", RoomItemController, only: [:delete]

    resources "/rooms", RoomController, only: [:show, :edit, :update] do
      resources "/exits", RoomExitController, only: [:new, :create], as: :exit

      resources "/items", RoomItemController, only: [:new, :create]

      resources "/shops", ShopController, only: [:new, :create]
    end

    resources "/sessions", SessionController, only: [:new, :create]

    resources "/shop_items", ShopItemController, only: [:delete]

    resources "/shops", ShopController, only: [:show, :edit, :update] do
      resources "/items", ShopItemController, only: [:new, :create]
    end

    resources "/skills", SkillController, only: [:show, :edit, :update]

    post "/users/teleport", UserController, :teleport
    post "/users/disconnect", UserController, :disconnect
    resources "/users", UserController, only: [:index, :show] do
      post "/reset", UserController, :reset, as: :reset
    end

    resources "/zones", ZoneController, only: [:index, :show, :new, :create, :edit, :update] do
      resources "/rooms", RoomController, only: [:new, :create]
    end
  end
end
