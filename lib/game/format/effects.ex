defmodule Game.Format.Effects do
  @moduledoc """
  Format functions for effects
  """

  import Game.Format.Context

  alias Game.Format

  @doc """
  Format effects for display.
  """
  def effects([], _target), do: []

  def effects([effect | remaining], target) do
    [render(effect, target) | effects(remaining, target)]
  end

  @doc """
  Render a single effect
  """
  def render(effect = %{kind: "damage"}, target) do
    context()
    |> assign(:amount, effect.amount)
    |> assign(:type, effect.type)
    |> assign(:target, Format.name(target))
    |> Format.template("[amount] [type] damage is dealt to [target].")
  end

  def render(effect = %{kind: "damage/over-time"}, target) do
    context()
    |> assign(:amount, effect.amount)
    |> assign(:type, effect.type)
    |> assign(:target, Format.name(target))
    |> Format.template("[amount] [type] damage is dealt to [target].")
  end

  def render(effect = %{kind: "recover", type: "health"}, target) do
    context()
    |> assign(:amount, effect.amount)
    |> assign(:target, Format.name(target))
    |> Format.template("[amount] damage is healed to [target].")
  end

  def render(effect = %{kind: "recover", type: "skill"}, _target) do
    context()
    |> assign(:amount, effect.amount)
    |> Format.template("[amount] skill points are recovered.")
  end

  def render(effect = %{kind: "recover", type: "endurance"}, _target) do
    context()
    |> assign(:amount, effect.amount)
    |> Format.template("[amount] endurance points are recovered.")
  end

  def render(_effect, _target), do: ""
end
