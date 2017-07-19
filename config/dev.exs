use Mix.Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_venture_dev",
  hostname: "localhost",
  pool_size: 10

config :ex_venture, :networking,
  server: true,
  socket_module: Networking.Protocol

config :ex_venture, :game,
  room: Game.Room
