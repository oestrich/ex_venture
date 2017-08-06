defmodule Game.ItemsTest do
  use ExUnit.Case

  alias Game.Items

  test "fetch an item" do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => :item} end)
    assert Items.item(1) == :item
  end

  test "a missing item" do
    Items.start_link
    Agent.update(Items, fn (_) -> %{} end)
    assert Items.item(1) == nil
  end

  test "fetch several items" do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => :sword, 2 => :shield} end)
    assert Items.items([1, 2]) == [:sword, :shield]
  end

  test "fetch several items - skips those not found" do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => :sword, 2 => :shield} end)
    assert Items.items([1, 3]) == [:sword]
  end

  describe "data reloading" do
    test "reload a single item" do
      Items.start_link
      Agent.update(Items, fn (_) -> %{1 => %{name: "sword"}} end)
      :ok = Items.reload(%{id: 1, name: "Sword"})
      assert Items.item(1) == %{id: 1, name: "Sword"}
    end

    test "push a new item in" do
      Items.start_link
      :ok = Items.insert(%{id: 10, name: "Sword"})
      assert Items.item(10) == %{id: 10, name: "Sword"}
    end
  end
end
