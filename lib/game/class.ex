defmodule Game.Class do
  @moduledoc """
  A behaviour for classes.
  """

  alias Data.Stats

  @doc """
  Name of the class
  """
  @callback name() :: String.t

  @doc """
  A description of the class
  """
  @callback description() :: String.t

  @doc """
  Starting stats that will be copied into the user
  """
  @callback starting_stats() :: Stats.character

  defmacro __using__(_opts) do
    quote do
      @behaviour Game.Class
    end
  end

  @classes [Game.Class.Fighter, Game.Class.Mage]

  @doc """
  List of classes
  """
  @spec classes() :: [atom]
  def classes(), do: @classes
end
