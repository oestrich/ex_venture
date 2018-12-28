use Mix.Config

{version, _} = System.cmd("git", ["rev-parse", "HEAD"])
config :ex_venture, version: String.trim(version)

config :ex_venture, Web.Endpoint,
  http: [port: 4000],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :ex_venture, :networking,
  port: 5555,
  server: true,
  socket_module: Networking.Protocol

config :ex_venture, :game,
  npc: Game.NPC,
  zone: Game.Zone,
  room: Game.Room,
  environment: Game.Environment,
  shop: Game.Shop,
  zone: Game.Zone,
  continue_wait: 500

config :logger, level: :info

if File.exists?("config/dev.secret.exs") do
  import_config("prod.secret.exs")
end
