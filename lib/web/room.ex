defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Room
  alias Data.Repo

  def get(id) do
    Room
    |> where([r], r.id == ^id)
    |> preload([:zone, :north, :east, :south, :west])
    |> Repo.one
  end

  def npcs(room_id) do
    NPC
    |> where([n], n.room_id == ^room_id)
    |> Repo.all
  end
end
