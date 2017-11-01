defmodule Web.Bug do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Bug
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all bugs
  """
  @spec all(opts :: Keyword.t) :: [Bug.t]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Bug
      |> order_by([b], desc: b.id)
      |> preload([:reporter])

    query |> Pagination.paginate(opts)
  end

  @doc """
  Get a bug
  """
  @spec get(id :: integer) :: [Class.t]
  def get(id) do
    Bug
    |> where([b], b.id == ^id)
    |> preload([:reporter])
    |> Repo.one
  end
end
