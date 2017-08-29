defmodule Web.EffectsHelper do
  def effects(%{changes: %{effects: effects}}) when effects != nil do
    effects(%{effects: effects})
  end
  def effects(%{data: %{effects: effects}}) when effects != nil do
    effects(%{effects: effects})
  end
  def effects(%{effects: effects}) when effects != nil do
    case Poison.encode(effects, pretty: true) do
      {:ok, effects} -> effects
      _ -> ""
    end
  end
  def effects(%{}), do: ""
end
