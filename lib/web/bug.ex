defmodule Web.Bug do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Bug
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  Get all bugs
  """
  @spec all(Keyword.t()) :: [Bug.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Bug
    |> order_by([b], desc: b.id)
    |> preload([:reporter])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"is_completed", is_completed}, query) do
    query |> where([b], b.is_completed == ^is_completed)
  end

  def filter_on_attribute(_, query), do: query

  @doc """
  Get a bug
  """
  @spec get(integer()) :: [Bug.t()]
  def get(id) do
    Bug
    |> where([b], b.id == ^id)
    |> preload([:reporter])
    |> Repo.one()
  end

  @doc """
  Mark a bug as completed
  """
  @spec complete(integer()) :: {:ok, Bug.t()}
  def complete(bug_id) do
    bug_id
    |> get()
    |> Bug.completed_changeset(%{is_completed: true})
    |> Repo.update()
  end
end
