defmodule Game.Class.Mage do
  @moduledoc """
  Mage class
  """

  use Game.Class

  def name(), do: "Mage"

  def description() do
    """
    Uses intelligence and magic to overcome.
    """
  end

  @doc """
  Starting stats for a mage
  """
  def starting_stats() do
    %{
      health: 25,
      strength: 10,
      dexterity: 12,
    }
  end
end
