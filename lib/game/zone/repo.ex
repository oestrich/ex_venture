defmodule Game.Zone.Repo do
  @moduledoc """
  Repo helper for the Zone modules
  """

  alias Data.Exit
  alias Data.Repo
  alias Data.Zone

  @doc """
  Load all zones
  """
  @spec all() :: [Zone.t()]
  def all() do
    Zone |> Repo.all()
  end

  def get(id) do
    Zone
    |> Repo.get(id)
    |> Exit.load_zone_exits()
  end
end
