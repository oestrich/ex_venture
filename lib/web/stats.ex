defmodule Web.Stats do
  @moduledoc """
  Dashboard Statistics
  """

  import Ecto.Query

  alias Data.Bug
  alias Data.Item
  alias Data.NPC
  alias Data.Repo
  alias Data.Room
  alias Data.User
  alias Data.Zone

  @doc """
  Count the number of users in the database
  """
  @spec user_count() :: integer()
  def user_count() do
    User
    |> select([u], count(u.id))
    |> Repo.one
  end

  @doc """
  Count the number of items in the database
  """
  @spec item_count() :: integer()
  def item_count() do
    Item
    |> select([i], count(i.id))
    |> Repo.one
  end

  @doc """
  Count the number of zones in the database
  """
  @spec zone_count() :: integer()
  def zone_count() do
    Zone
    |> select([z], count(z.id))
    |> Repo.one
  end

  @doc """
  Count the number of rooms in the database
  """
  @spec room_count() :: integer()
  def room_count() do
    Room
    |> select([r], count(r.id))
    |> Repo.one
  end

  @doc """
  Count the number of npcs in the database
  """
  @spec npc_count() :: integer()
  def npc_count() do
    NPC
    |> select([n], count(n.id))
    |> Repo.one
  end

  @doc """
  Count the number of bugs in the database
  """
  @spec bug_count() :: integer()
  def bug_count() do
    Bug
    |> select([b], count(b.id))
    |> Repo.one
  end
end
