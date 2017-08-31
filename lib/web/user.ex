defmodule Web.User do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.User
  alias Data.Repo

  @doc """
  Fetch a user from a web token
  """
  @spec from_token(token :: String.t) :: User.t
  def from_token(token) do
    User
    |> where([u], u.token == ^token)
    |> Repo.one
  end

  @doc """
  Load all users
  """
  @spec all() :: [User.t]
  def all() do
    User
    |> order_by([u], u.id)
    |> Repo.all
  end

  @doc """
  Load a user
  """
  @spec get(id :: integer) :: User.t
  def get(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:class])
  end
end
