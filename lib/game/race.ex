defmodule Game.Race do
  @moduledoc """
  A behaviour for races.
  """

  alias Data.Race
  alias Data.Repo

  @doc """
  List of races
  """
  @spec races() :: [Race.t()]
  def races() do
    Race
    |> Repo.all()
  end
end
