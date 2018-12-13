use Mix.Config

# This goes in `/etc/exventure.config.exs`

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "CHANGEME",
  hostname: "CHANGEME",
  port: "CHANGEME",
  ssl: true,
  username: "CHANGEME",
  password: "CHANGEME",
  pool_size: 20

config :ex_venture, ExVenture.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "CHANGEME",
  port: "587",
  username: "CHANGEME",
  password: "CHANGEME"

config :ex_venture, :mailer, from: "CHANGEME"

config :ex_venture, Web.Endpoint,
  url: [host: "CHANGEME", port: 443, scheme: "https"]

config :ex_venture, :networking,
  host: "CHANGEME",
  ssl_port: "5443"

config :gossip, :client_id, "CHANGEME"
config :gossip, :client_secret, "CHANGEME"

config :pid_file, file: "/home/deploy/ex_venture.pid"

config :ex_venture, :errors, report: true

config :sentry,
  dsn: "CHANGEME",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"},
  included_environments: [:prod]

config :logger,
  backends: [
    {LoggerFileBackend, :global},
    {LoggerFileBackend, :phoenix},
    {LoggerFileBackend, :commands}
  ]

config :logger, :global, path: "/var/log/ex_venture/global.log"

config :logger, :phoenix,
  path: "/var/log/ex_venture/phoenix.log",
  level: :info,
  metadata_filter: [type: :phoenix]

config :logger, :commands,
  path: "/var/log/ex_venture/commands.log",
  level: :info,
  metadata_filter: [type: :command]
