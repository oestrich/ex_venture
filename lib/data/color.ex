defmodule Data.Color do
  @moduledoc """
  Static color data
  """

  @doc """
  Valid color codes
  """
  def options() do
    [
      "black",
      "red",
      "green",
      "yellow",
      "blue",
      "magenta",
      "cyan",
      "white"
    ]
  end

  @doc """
  Valid map color codes
  """
  def map_colors() do
    [
      "blue",
      "brown",
      "dark-green",
      "green",
      "grey",
      "light-grey"
    ]
  end

  @doc """
  Color "tags" or semantic colors for things in the game like an NPC
  """
  def color_tags() do
    [
      "npc",
      "item",
      "player",
      "skill",
      "quest",
      "room",
      "say",
      "command",
      "exit",
      "shop",
      "hint"
    ]
  end
end
