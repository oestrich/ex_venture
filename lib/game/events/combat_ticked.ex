defmodule Game.Events.CombatTicked do
  @moduledoc """
  Event for an NPC ticking in combat
  """

  defstruct [type: "combat/ticked"]
end
