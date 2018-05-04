defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :public do
    plug(Web.Plug.LoadUser)
  end

  pipeline :public_2fa do
    plug(Web.Plug.LoadUser, verify: false)
  end

  scope "/", Web, as: :public do
    pipe_through([:browser, :public_2fa])

    get("/account/twofactor/verify", AccountTwoFactorController, :verify)
    post("/account/twofactor/verify", AccountTwoFactorController, :verify_token)
  end

  scope "/", Web, as: :public do
    pipe_through([:browser, :public])

    get("/css/colors.css", ColorController, :index)

    get("/", PageController, :index)

    get("/account", AccountController, :show)
    get("/account/password", AccountController, :password)
    put("/account", AccountController, :update)

    get("/account/twofactor/start", AccountTwoFactorController, :start)
    get("/account/twofactor/qr.png", AccountTwoFactorController, :qr)
    post("/account/twofactor", AccountTwoFactorController, :validate)
    delete("/account/twofactor", AccountTwoFactorController, :clear)

    resources("/account/mail", MailController, only: [:index, :show])

    get("/announcements/atom", AnnouncementController, :feed)
    resources("/announcements", AnnouncementController, only: [:show])

    resources("/classes", ClassController, only: [:index, :show])

    get("/help/commands", HelpController, :commands)
    get("/help/commands/:command", HelpController, :command)
    resources("/help", HelpController, only: [:index, :show])
    get("/help/builtin/:id", HelpController, :built_in)

    get("/play", PlayController, :show)

    resources("/races", RaceController, only: [:index, :show])

    resources("/register", RegistrationController, only: [:new, :create])

    delete("/sessions", SessionController, :delete)
    resources("/sessions", SessionController, only: [:new, :create])

    resources("/skills", SkillController, only: [:index, :show])

    get("/who", PageController, :who)
  end

  scope "/admin", Web.Admin do
    pipe_through(:browser)

    get("/", DashboardController, :index)

    resources("/announcements", AnnouncementController, except: [:delete])

    resources "/bugs", BugController, only: [:index, :show] do
      post("/complete", BugController, :complete, as: :complete)
    end

    resources("/channels", ChannelController, only: [:index, :new, :create, :edit, :update])

    resources "/classes", ClassController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/skills", ClassSkillController, only: [:new, :create], as: :skill)
    end

    resources("/class_skills", ClassSkillController, only: [:delete])

    resources("/color_codes", ColorCodeController, except: [:show, :delete])

    resources("/config", ConfigController, only: [:index, :edit, :update])

    resources("/damage_types", DamageTypeController, except: [:show, :delete])

    resources("/exits", RoomExitController, only: [:delete], as: :exit)

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

    resources("/room_items", RoomItemController, only: [:delete])

    resources "/rooms", RoomController, only: [:show, :edit, :update] do
      resources("/exits", RoomExitController, only: [:new, :create], as: :exit)

      resources(
        "/features",
        RoomFeatureController,
        only: [:new, :create, :edit, :update, :delete],
        as: :feature
      )

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

    post("/users/teleport", UserController, :teleport)
    post("/users/disconnect", UserController, :disconnect)

    resources "/users", UserController, only: [:index, :show, :edit, :update] do
      post("/reset", UserController, :reset, as: :reset)
      get("/watch", UserController, :watch, as: :watch)
    end

    resources "/zones", ZoneController, only: [:index, :show, :new, :create, :edit, :update] do
      resources("/rooms", RoomController, only: [:new, :create])
    end
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.EmailPreviewPlug)
  end
end
