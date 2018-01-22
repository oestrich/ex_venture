defmodule Game.Class do
  @moduledoc """
  A behaviour for classes.
  """

  alias Data.Class
  alias Data.Repo

  @doc """
  List of classes
  """
  @spec classes() :: [Data.Class.t()]
  def classes() do
    Class
    |> Repo.all()
  end
end
