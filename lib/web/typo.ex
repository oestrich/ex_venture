defmodule Web.Typo do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Repo
  alias Data.Typo
  alias Web.Pagination

  @doc """
  Get all typos
  """
  @spec all(opts :: Keyword.t) :: [Typo.t]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Typo
      |> order_by([b], desc: b.id)
      |> preload([:reporter, :room])

    query |> Pagination.paginate(opts)
  end

  @doc """
  Get a typo
  """
  @spec get(id :: integer) :: [Class.t]
  def get(id) do
    Typo
    |> where([b], b.id == ^id)
    |> preload([:reporter, :room])
    |> Repo.one
  end
end
