defmodule Web.Race do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Race
  alias Data.Repo

  @doc """
  Get all classes
  """
  @spec all() :: [Race.t]
  def all() do
    Race
    |> order_by([r], r.id)
    |> Repo.all
  end

  @doc """
  Get a class

  Preload skills
  """
  @spec get(id :: integer) :: [Race.t]
  def get(id) do
    Race
    |> where([c], c.id == ^id)
    |> Repo.one
  end
end
