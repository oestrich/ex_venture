defmodule Game.Format.ShopsTest do
  use ExUnit.Case

  alias Game.Format.Shops

  doctest Game.Format.Shops

  describe "shop listing" do
    setup do
      sword = %{name: "Sword", price: 100, quantity: 10}
      shield = %{name: "Shield", price: 80, quantity: -1}
      %{shop: %{name: "Tree Top Stand"}, items: [sword, shield]}
    end

    test "includes shop name", %{shop: shop, items: items} do
      assert Regex.match?(~r/Tree Top Stand/, Shops.list(shop, items))
    end

    test "includes shop items", %{shop: shop, items: items} do
      assert Regex.match?(~r/100 gold/, Shops.list(shop, items))
      assert Regex.match?(~r/10 left/, Shops.list(shop, items))
      assert Regex.match?(~r/Sword/, Shops.list(shop, items))
    end

    test "-1 quantity is unlimited", %{shop: shop, items: items} do
      assert Regex.match?(~r/unlimited/, Shops.list(shop, items))
    end
  end
end
