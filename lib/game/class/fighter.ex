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
end
