defmodule Web.Role do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Role
  alias Data.Repo

  @doc false
  def resources(), do: Role.resources()

  @doc false
  def accesses(), do: Role.accesses()

  @doc """
  Get all roles
  """
  @spec all() :: [Role.t()]
  def all() do
    Role
    |> order_by([r], asc: r.name)
    |> Repo.all()
  end

  @doc """
  Get a role
  """
  @spec get(integer()) :: [Role.t()]
  def get(id) do
    Role
    |> where([n], n.id == ^id)
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: map()
  def new(), do: %Role{} |> Role.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Role.t()) :: map()
  def edit(role), do: role |> Role.changeset(%{})

  @doc """
  Create a role
  """
  @spec create(map()) :: {:ok, Role.t()} | {:error, map}
  def create(params) do
    %Role{}
    |> Role.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an zone
  """
  @spec update(integer(), map()) :: {:ok, Zone.t()} | {:error, map()}
  def update(id, params) do
    id
    |> get()
    |> Role.changeset(cast_params(params))
    |> Repo.update()
  end

  defp cast_params(params) do
    case Map.fetch(params, "permissions") do
      {:ok, permissions} ->
        permissions = Enum.reject(permissions, &(&1 == ""))
        Map.put(params, "permissions", permissions)

      :error ->
        params
    end
  end
end
