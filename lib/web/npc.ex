defmodule Web.NPC do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Repo

  @doc """
  Get all npcs
  """
  @spec all() :: [NPC.t]
  def all() do
    NPC
    |> order_by([n], n.id)
    |> Repo.all
  end

  @doc """
  Get a npc
  """
  @spec get(id :: integer) :: [NPC.t]
  def get(id) do
    NPC
    |> where([c], c.id == ^id)
    |> Repo.one
  end
end
