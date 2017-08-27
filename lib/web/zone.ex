defmodule Web.Zone do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Zone
  alias Data.Room
  alias Data.Repo

  alias Game.Zone.Supervisor, as: ZoneSupervisor

  def all() do
    Zone |> Repo.all
  end

  def get(id) do
    Zone
    |> where([z], z.id == ^id)
    |> preload([rooms: ^(from r in Room, order_by: r.id)])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Zone{} |> Zone.changeset(%{})

  @doc """
  Create a zone
  """
  @spec create(params :: map) :: {:ok, Zone.t} | {:error, changeset :: map}
  def create(params) do
    changeset = %Zone{} |> Zone.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, zone} ->
        ZoneSupervisor.start_child(zone)
        {:ok, zone}
      anything -> anything
    end
  end
end
