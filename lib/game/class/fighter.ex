defmodule Game.Class.Fighter do
  @moduledoc """
  Fighter class
  """

  use Game.Class

  def name(), do: "Fighter"

  def description() do
    """
    Uses strength and swords to overcome.
    """
  end

  @doc """
  Starting stats for a fighter
  """
  def starting_stats() do
    %{
      health: 25,
      strength: 13,
      dexterity: 10,
    }
  end
end
