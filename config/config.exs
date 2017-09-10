# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_venture,
  ecto_repos: [Data.Repo],
  namespace: Web

config :ex_venture, :game,
  currency: "gold",
  rand: :rand

# Configures the endpoint
config :ex_venture, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7mps3fp2M1dk3Cnd8Wu/91TdGWhzrh3PC3naZcn/umPyZabQQL2Zq8yysm9WMkc3",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Web.PubSub, adapter: Phoenix.PubSub.PG2]

import_config "#{Mix.env}.exs"

config :distillery,
  no_warn_missing: [:elixir_make]
