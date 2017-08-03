use Mix.Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_venture_dev",
  hostname: "localhost",
  pool_size: 10

config :ex_venture, Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin", cd: Path.expand("../assets", __DIR__)]]

config :ex_venture, :networking,
  server: true,
  socket_module: Networking.Protocol

config :ex_venture, :game,
  room: Game.Room
