use Mix.Config

#
# If you're looking to update variables, you probably want to:
# - Edit `.env.test`
# - Add to `ExVenture.Config` for loading through Vapor
#

# Configure your database
config :ex_venture, ExVenture.Repo, pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_venture, Web.Endpoint,
  http: [port: 4002],
  server: false

config :ex_venture, ExVenture.Mailer, adapter: Bamboo.TestAdapter

config :ex_venture, :listener, start: false

# Print only warnings and errors during test
config :logger, level: :warn

config :bcrypt_elixir, :log_rounds, 4

config :stein_storage, backend: :test
