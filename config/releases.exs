import Config

config :ex_venture, ExVenture.Repo, ssl: true

config :ex_venture, Web.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :ex_venture, ExVenture.Mailer, adapter: Bamboo.LocalAdapter

config :logger, level: :info

config :phoenix, :logger, false

config :stein_phoenix, :views, error_helpers: Web.ErrorHelpers
