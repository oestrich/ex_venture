defmodule Data.Repo do
  use Ecto.Repo,
    otp_app: :ex_venture,
    adapter: Ecto.Adapters.Postgres
end
