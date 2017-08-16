defmodule Game.ItemTest do
  use ExUnit.Case
  doctest Game.Item

  alias Game.Item
  alias Game.Items

  test "load item effects from a player's save" do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => %{effects: [:effects]}} end)

    assert Item.effects_from_wearing(%{wearing: %{chest: 1}}) == [:effects]
  end

  test "load item effects from a player's save - empty" do
    assert Item.effects_from_wearing(%{}) == []
  end
end
