defmodule Web.Zone do
  import Ecto.Query

  alias Data.Zone
  alias Data.Room
  alias Data.Repo

  def all() do
    Zone |> Repo.all
  end

  def get(id) do
    Zone
    |> where([z], z.id == ^id)
    |> preload([rooms: ^(from r in Room, order_by: r.id)])
    |> Repo.one
  end
end
