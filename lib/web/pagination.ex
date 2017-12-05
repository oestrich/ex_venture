defmodule Web.Pagination do
  @moduledoc """
  Paginate an Ecto query
  """

  defstruct page: [], pagination: %{}

  @type t :: %__MODULE__{}

  import Ecto.Query

  alias Data.Repo

  @doc """
  Paginate a query

  Returns the current and total pages
  """
  @spec paginate(query :: Ecto.Query.t, pagination_params :: map) :: Ecto.Query.t | t
  def paginate(query, %{page: page, per: per}) do
    offset = (page - 1) * per

    count =
      query
      |> select([u], count(u.id))
      |> exclude(:order_by)
      |> exclude(:preload)
      |> Repo.one
      |> ensure_number()

    total_pages = round(Float.ceil(count / per))

    query =
      query
      |> limit(^per)
      |> offset(^offset)
      |> Repo.all

    %__MODULE__{page: query, pagination: %{current: page, total: total_pages, empty?: total_pages == 0}}
  end
  def paginate(query, _), do: query |> Repo.all

  defp ensure_number(nil), do: 0
  defp ensure_number(count) when is_integer(count), do: count
end
