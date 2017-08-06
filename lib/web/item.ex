defmodule Web.Item do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Item
  alias Data.Repo

  def all() do
    Item |> Repo.all
  end

  def get(id) do
    Item |> Repo.get(id)
  end
end
