defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Room
  alias Data.Repo

  def get(id) do
    Room
    |> where([r], r.id == ^id)
    |> preload([:zone, :north, :east, :south, :west, :npcs])
    |> Repo.one
  end
end
