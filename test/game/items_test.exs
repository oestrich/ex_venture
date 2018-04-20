defmodule Game.ItemsTest do
  use ExUnit.Case
  import Test.ItemsHelper

  alias Game.Items

  setup do
    start_and_clear_items()
    :ok
  end

  test "fetch an item" do
    Items.insert(%{id: 1})
    ensure_process_caught_up(Items)

    assert Items.item(1) == %{id: 1}
  end

  test "a missing item" do
    assert Items.item(1) == nil
  end

  test "fetch several items" do
    Items.insert(%{id: 1, name: "Sword"})
    Items.insert(%{id: 2, name: "Shield"})
    ensure_process_caught_up(Items)

    assert Items.items([1, 2]) == [%{id: 1, name: "Sword"}, %{id: 2, name: "Shield"}]
  end

  test "fetch several items - skips those not found" do
    Items.insert(%{id: 1, name: "Sword"})
    Items.insert(%{id: 2, name: "Shield"})
    ensure_process_caught_up(Items)

    assert Items.items([1, 3]) == [%{id: 1, name: "Sword"}]
  end

  describe "data reloading" do
    test "reload a single item" do
      Items.insert(%{id: 1, name: "Sword"})
      ensure_process_caught_up(Items)

      [:ok] = Items.reload(%{id: 1, name: "Sword"})
      assert Items.item(1) == %{id: 1, name: "Sword"}
    end

    test "push a new item in" do
      [:ok] = Items.insert(%{id: 10, name: "Sword"})
      ensure_process_caught_up(Items)
      assert Items.item(10) == %{id: 10, name: "Sword"}
    end
  end
end
