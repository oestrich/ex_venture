defmodule Web.Stats do
  @moduledoc """
  Dashboard Statistics
  """

  import Ecto.Query

  alias Data.Item
  alias Data.Room
  alias Data.User
  alias Data.Zone
  alias Data.Repo

  def user_count() do
    User
    |> select([u], count(u.id))
    |> Repo.one
  end

  def item_count() do
    Item
    |> select([i], count(i.id))
    |> Repo.one
  end

  def zone_count() do
    Zone
    |> select([z], count(z.id))
    |> Repo.one
  end

  def room_count() do
    Room
    |> select([r], count(r.id))
    |> Repo.one
  end
end
