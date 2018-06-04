defmodule Game.Environment.State do
  @moduledoc """
  Environment state around the player.

  The room's name, description, who else is in the room with the player, etc
  """

  defstruct [
    :id,
    :zone_id,
    :zone,
    :name,
    :description,
    :currency,
    :items,
    :listen,
    :x,
    :y,
    :map_layer,
    :ecology,
    :shops,
    :exits,
    players: [],
    npcs: [],
    features: [],
  ]
end
