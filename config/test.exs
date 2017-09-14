use Mix.Config

config :logger,
  level: :error

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_venture_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_venture, :networking,
  host: "localhost",
  port: 5555,
  server: false,
  socket_module: Test.Networking.Socket

config :ex_venture, :game,
  room: Test.Game.Room,
  shop: Test.Game.Shop,
  zone: Test.Game.Zone,
  rand: Test.DropChanceSuccess

config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1
