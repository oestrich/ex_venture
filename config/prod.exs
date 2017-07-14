use Mix.Config

config :ex_mud, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_mud",
  hostname: "localhost",
  pool_size: 10

config :ex_mud, :networking,
  server: true,
  socket_module: Networking.Protocol
