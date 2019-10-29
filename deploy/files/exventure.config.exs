import Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "exventure",
  port: "5432",
  pool_size: 20

config :ex_venture, ExVenture.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "",
  port: "587",
  username: "",
  password: ""

config :ex_venture, :mailer, from: ""

config :ex_venture, Web.Endpoint,
  url: [host: "", port: 443, scheme: "https"]

config :ex_venture, :networking,
  host: "",
  ssl_port: "5443"

config :pid_file, file: "/home/deploy/ex_venture.pid"

config :ex_venture, :errors, report: false

config :gossip, :client_id, ""
config :gossip, :client_secret, ""
