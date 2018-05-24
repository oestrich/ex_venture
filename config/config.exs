# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_venture,
  ecto_repos: [Data.Repo],
  namespace: Web,
  timezone: "America/New_York",
  version: "development"

config :ex_venture, :game,
  world: true,
  currency: "gold",
  timeout_seconds: 10 * 60,
  rand: :rand,
  random_damage: -25..25,
  report_users: true

config :ex_venture, :cluster, size: 1

config :ex_venture, :errors, report: false

# Configures the endpoint
config :ex_venture, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7mps3fp2M1dk3Cnd8Wu/91TdGWhzrh3PC3naZcn/umPyZabQQL2Zq8yysm9WMkc3",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Web.PubSub, adapter: Phoenix.PubSub.PG2]

config :ex_venture, Data.Repo, loggers: [Metrics.RepoInstrumenter, Ecto.LogEntry]

config :distillery, no_warn_missing: [:elixir_make]

config :prometheus, Metrics.PipelineInstrumenter,
  labels: [:status_class, :method, :host, :scheme],
  duration_buckets: [
    10,
    100,
    1_000,
    10_000,
    100_000,
    300_000,
    500_000,
    750_000,
    1_000_000,
    1_500_000,
    2_000_000,
    3_000_000
  ],
  registry: :default,
  duration_unit: :microseconds

import_config "#{Mix.env()}.exs"
