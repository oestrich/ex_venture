defmodule Web.Skill do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Skill
  alias Data.Repo

  @doc """
  Get a skill
  """
  @spec get(id :: integer) :: Skill.t
  def get(id) do
    Skill |> Repo.get(id) |> Repo.preload([:class])
  end
end
