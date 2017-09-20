defmodule Web.Pagination do
  defstruct page: [], pagination: %{}

  import Ecto.Query

  alias Data.Repo

  def paginate(query, %{page: page, per: per}) do
    offset = (page - 1) * per

    count =
      query
      |> select([u], count(u.id))
      |> exclude(:order_by)
      |> Repo.one

    total_pages = round(Float.ceil(count / per))

    query =
      query
      |> limit(^per)
      |> offset(^offset)
      |> Repo.all

    %__MODULE__{page: query, pagination: %{current: page, total: total_pages}}
  end
  def paginate(query, _), do: query |> Repo.all
end
