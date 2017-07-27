defmodule Game.Zone.Repo do
  alias Data.Repo
  alias Data.Zone

  @doc """
  Load all zones
  """
  @spec all() :: [Zone.t]
  def all() do
    Zone |> Repo.all
  end
end
