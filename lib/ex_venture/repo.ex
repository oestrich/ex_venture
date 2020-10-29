defmodule ExVenture.Repo do
  use Ecto.Repo,
    otp_app: :ex_venture,
    adapter: Ecto.Adapters.Postgres

  alias ExVenture.Config

  def init(_type, config) do
    vapor_config = Config.database()

    config =
      Keyword.merge(config,
        url: vapor_config.database_url,
        pool_size: vapor_config.pool_size
      )

    {:ok, config}
  end
end
