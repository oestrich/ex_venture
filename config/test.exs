use Mix.Config

config :logger, level: :error

config :ex_venture, Data.Repo,
  database: "ex_venture_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_venture, :networking,
  host: "localhost",
  port: 5555,
  server: false,
  socket_module: Test.Networking.Socket

config :ex_venture, :game,
  world: false,
  npc: Test.Game.NPC,
  zone: Test.Game.Zone,
  room: Test.Game.Room,
  environment: Test.Game.Environment,
  shop: Test.Game.Shop,
  zone: Test.Game.Zone,
  rand: Test.ChanceSuccess,
  report_players: false,
  continue_wait: 10,
  random_effect_range: 0..0

config :ex_venture, :npc, reaction_time_ms: 0

config :bcrypt_elixir, :log_rounds, 4

config :ex_venture, :mailer, from: "mud@example.com"
config :ex_venture, ExVenture.Mailer, adapter: Bamboo.TestAdapter
