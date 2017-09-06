defmodule Web.HelpTopic do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.HelpTopic
  alias Data.Repo

  @doc """
  Get all help_topics
  """
  @spec all() :: [HelpTopic.t]
  def all() do
    HelpTopic
    |> order_by([z], z.id)
    |> Repo.all
  end

  @doc """
  Get a help topic
  """
  @spec get(id :: integer) :: [HelpTopic.t]
  def get(id) do
    HelpTopic
    |> Repo.get(id)
  end
end
