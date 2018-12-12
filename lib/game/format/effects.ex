defmodule Game.Format.Effects do
  @moduledoc """
  Format functions for effects
  """

  alias Game.Format

  @doc """
  Format effects for display.
  """
  def effects([], _target), do: []

  def effects([effect | remaining], target) do
    case effect do
      %{kind: "damage"} ->
        [
          "#{effect.amount} #{effect.type} damage is dealt to #{Format.name(target)}."
          | effects(remaining, target)
        ]

      %{kind: "damage/over-time"} ->
        [
          "#{effect.amount} #{effect.type} damage is dealt to #{Format.name(target)}."
          | effects(remaining, target)
        ]

      %{kind: "recover", type: "health"} ->
        [
          "#{effect.amount} damage is healed to #{Format.name(target)}."
          | effects(remaining, target)
        ]

      %{kind: "recover", type: "skill"} ->
        ["#{effect.amount} skill points are recovered." | effects(remaining, target)]

      %{kind: "recover", type: "endurance"} ->
        ["#{effect.amount} endurance points are recovered." | effects(remaining, target)]

      _ ->
        effects(remaining, target)
    end
  end
end
