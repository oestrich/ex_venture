defmodule ExVenture.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :ex_venture,
    adapter: Ecto.Adapters.Postgres

  alias ExVenture.Config
  alias Stein.Pagination

  def init(_type, config) do
    vapor_config = Config.database()

    config =
      Keyword.merge(config,
        url: vapor_config.database_url,
        pool_size: vapor_config.pool_size
      )

    {:ok, config}
  end

  def paginate(query, page, per) when is_integer(page) and is_integer(per) do
    Pagination.paginate(__MODULE__, query, %{page: page, per: per})
  end

  def paginate(query, _page, _per), do: __MODULE__.all(query)
end
