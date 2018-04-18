use Mix.Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_venture_dev",
  hostname: "localhost",
  pool_size: 10

config :ex_venture, Web.Endpoint,
  http: [port: {:system, "PORT"}],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  server: true,
  watchers: [
    node: [
      "node_modules/brunch/bin/brunch",
      "watch",
      "--stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :ex_venture, :networking,
  host: "localhost",
  port: {:system, "TELNET_PORT", 5555},
  server: true,
  socket_module: Networking.Protocol

config :ex_venture, :game,
  npc: Game.NPC,
  room: Game.Room,
  shop: Game.Shop,
  zone: Game.Zone,
  continue_wait: 500

config :logger, :level, :info

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:type]

config :ex_venture, ExVenture.Mailer, adapter: Bamboo.LocalAdapter

config :ex_venture, :mailer, from: "mud@example.com"

config :libcluster,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: []]
    ]
  ]
