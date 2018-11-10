defmodule Web.Router do
  use Web, :router

  @report_errors Application.get_env(:ex_venture, :errors)[:report]

  if @report_errors do
    use Plug.ErrorHandler
    use Sentry.Plug
  end

  pipeline :accepts_browser do
    plug(:accepts, ["html", "json"])
  end

  pipeline :accepts_api do
    plug(:accepts, ["html", "json", "hal", "siren", "collection", "mason", "jsonapi"])
  end

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :public do
    plug(Web.Plug.LoadUser)
    plug(Web.Plug.LoadCharacter)
  end

  pipeline :public_2fa do
    plug(Web.Plug.LoadUser, verify: false)
    plug(Web.Plug.LoadCharacter)
  end

  scope "/", Web, as: :public do
    pipe_through([:accepts_browser, :browser, :public_2fa])

    get("/account/twofactor/verify", AccountTwoFactorController, :verify)
    post("/account/twofactor/verify", AccountTwoFactorController, :verify_token)
  end

  scope "/", Web, as: :public do
    pipe_through([:accepts_api, :browser, :public])

    get("/", PageController, :index)

    resources("/classes", ClassController, only: [:index, :show])

    resources("/races", RaceController, only: [:index, :show])

    resources("/skills", SkillController, only: [:index, :show])

    resources("/who", WhoController, only: [:index])
  end

  scope "/", Web, as: :public do
    pipe_through([:accepts_browser, :browser, :public])

    get("/css/colors.css", ColorController, :index)
    get("/clients/mudlet/ex_venture.xml", PageController, :mudlet_package)
    get("/clients/map.xml", PageController, :map)

    get("/version", PageController, :version)

    get("/account", AccountController, :show)
    put("/account", AccountController, :update)

    resources("/account/characters", CharacterController, only: [:new, :create])
    post("/account/characters/swap", CharacterController, :swap)

    get("/account/twofactor/start", AccountTwoFactorController, :start)
    get("/account/twofactor/qr.png", AccountTwoFactorController, :qr)
    post("/account/twofactor", AccountTwoFactorController, :validate)
    delete("/account/twofactor", AccountTwoFactorController, :clear)

    resources("/account/mail", MailController, only: [:index, :show, :new, :create])

    get("/announcements/atom", AnnouncementController, :feed)
    resources("/announcements", AnnouncementController, only: [:show])

    get("/chat", ChatController, :show)

    get("/connection/authorize", ConnectionController, :authorize)
    post("/connection/authorize", ConnectionController, :connect)

    get("/help/commands", HelpController, :commands)
    get("/help/commands/:command", HelpController, :command)
    resources("/help", HelpController, only: [:index, :show])
    get("/help/builtin/:id", HelpController, :built_in)

    get("/play", PlayController, :show)

    get("/register/reset", RegistrationResetController, :new)
    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)
    post("/register/reset/verify", RegistrationResetController, :update)

    resources("/register", RegistrationController, only: [:new, :create])
    get("/register/finalize", RegistrationController, :finalize)
    post("/register/finalize", RegistrationController, :update)

    delete("/sessions", SessionController, :delete)
    resources("/sessions", SessionController, only: [:new, :create])

    get "/auth/:provider", AuthController, :request
    get "/auth/:provider/callback", AuthController, :callback
    post "/auth/:provider/callback", AuthController, :callback
  end

  scope "/admin", Web.Admin do
    pipe_through([:accepts_browser, :browser])

    get("/", DashboardController, :index)

    resources("/announcements", AnnouncementController, except: [:delete])

    resources "/bugs", BugController, only: [:index, :show] do
      post("/complete", BugController, :complete, as: :complete)
    end

    resources(
      "/channels",
      ChannelController,
      only: [:index, :new, :show, :create, :edit, :update]
    )

    resources "/classes", ClassController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/skills", ClassSkillController, only: [:new, :create], as: :skill)
    end

    resources("/class_skills", ClassSkillController, only: [:delete])

    resources("/characters", CharacterController, only: [:show]) do
      delete("/disconnect", CharacterController, :disconnect, as: :disconnect)
      get("/watch", CharacterController, :watch, as: :watch)
      post("/reset", CharacterController, :reset, as: :reset)
    end

    post("/characters/teleport", CharacterController, :teleport)
    post("/characters/disconnect", CharacterController, :disconnect)

    get("/colors", ColorController, :index)
    post("/colors", ColorController, :update)
    delete("/colors", ColorController, :delete)

    resources("/color_codes", ColorCodeController, only: [:new, :create, :edit, :update])

    resources("/config", ConfigController, only: [:index, :edit, :update])

    resources("/damage_types", DamageTypeController, except: [:show, :delete])

    resources("/exits", RoomExitController, only: [:delete], as: :exit)

    resources("/features", FeatureController)

    resources(
      "/help_topics",
      HelpTopicController,
      only: [:index, :show, :new, :create, :edit, :update]
    )

    resources("/insights", InsightController, only: [:index])

    resources "/items", ItemController, only: [:index, :show, :edit, :update, :new, :create] do
      resources("/aspects", ItemAspectingController, only: [:new, :create], as: :aspecting)
    end

    resources(
      "/item_aspects",
      ItemAspectController,
      only: [:index, :show, :edit, :update, :new, :create]
    )

    resources("/item_aspectings", ItemAspectingController, only: [:delete])

    resources("/notes", NoteController, only: [:index, :show, :new, :create, :edit, :update])

    resources "/npcs", NPCController, only: [:index, :show, :edit, :update, :new, :create] do
      post("/events/reload", NPCEventController, :reload)

      resources("/events", NPCEventController, except: [:show], as: :event)

      resources("/items", NPCItemController, only: [:new, :create], as: :item)

      get("/script", NPCScriptController, :show, as: :script)
      get("/script/edit", NPCScriptController, :edit, as: :script)
      put("/script", NPCScriptController, :update, as: :script)

      resources("/skills", NPCSkillController, only: [:new, :create, :delete], as: :skill)

      resources("/spawners", NPCSpawnerController, only: [:new, :create], as: :spawner)
    end

    resources("/npc_items", NPCItemController, only: [:edit, :update, :delete])

    resources("/npc_spawners", NPCSpawnerController, only: [:show, :edit, :update, :delete])

    resources("/quest_relations", QuestRelationController, only: [:delete])

    resources("/quest_steps", QuestStepController, only: [:edit, :update, :delete])

    resources "/quests", QuestController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/relations", QuestRelationController, only: [:new, :create], as: :relation)

      resources("/steps", QuestStepController, only: [:new, :create], as: :step)
    end

    resources "/races", RaceController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/skills", RaceSkillController, only: [:new, :create], as: :skill)
    end

    resources("/race_skills", RaceSkillController, only: [:delete])

    resources("/roles", RoleController, except: [:delete])

    resources("/room_items", RoomItemController, only: [:delete])

    resources "/rooms", RoomController, only: [:show, :edit, :update, :delete] do
      resources("/exits", RoomExitController, only: [:new, :create], as: :exit)

      resources(
        "/features",
        RoomFeatureController,
        only: [:new, :create, :edit, :update, :delete],
        as: :feature
      )

      resources("/features/global", RoomGlobalFeatureController, only: [:new, :create, :delete], as: :global_feature)

      resources("/items", RoomItemController, only: [:new, :create])

      resources("/shops", ShopController, only: [:new, :create])
    end

    resources("/sessions", SessionController, only: [:new, :create])

    resources("/shop_items", ShopItemController, only: [:edit, :update, :delete])

    resources "/shops", ShopController, only: [:show, :edit, :update] do
      resources("/items", ShopItemController, only: [:new, :create])
    end

    resources("/skills", SkillController, only: [:index, :show, :new, :create, :edit, :update])

    resources("/socials", SocialController, only: [:index, :show, :new, :create, :edit, :update])

    resources("/typos", TypoController, only: [:index, :show])

    resources "/users", UserController, only: [:index, :show, :edit, :update] do
      get("/cheat", UserController, :cheat, as: :cheat)
      post("/cheat/activate", UserController, :cheating, as: :cheating)
    end

    resources "/zones", ZoneController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/rooms", RoomController, only: [:new, :create])
    end

    get("/zones/:id/overworld/exits", ZoneOverworldController, :exits)
    post("/zones/:id/overworld/exits", ZoneOverworldController, :create_exit)
    delete("/zones/:id/overworld/exits/:exit_id", ZoneOverworldController, :delete_exit)
    put("/zones/:id/overworld", ZoneOverworldController, :update)
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
