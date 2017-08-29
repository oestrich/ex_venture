defmodule Web.Class do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Class
  alias Data.Repo

  @doc """
  Get all classes
  """
  @spec all() :: [Class.t]
  def all() do
    Class |> Repo.all
  end

  @doc """
  Get a class

  Preload skills
  """
  @spec get(id :: integer) :: [Class.t]
  def get(id) do
    Class
    |> where([z], z.id == ^id)
    |> preload([:skills])
    |> Repo.one
  end
end
