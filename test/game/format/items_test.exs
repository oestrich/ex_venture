defmodule Game.Format.ItemsTest do
  use ExUnit.Case

  alias Game.Format.Items

  doctest Game.Format.Items

  describe "inventory formatting" do
    setup do
      wearing = %{chest: %{name: "Leather Armor"}}
      wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      items = [
        %{item: %{name: "Potion"}, quantity: 2},
        %{item: %{name: "Dagger"}, quantity: 1},
      ]

      %{currency: 10, wearing: wearing, wielding: wielding, items: items}
    end

    test "displays currency", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You have 10 gold/, Items.inventory(currency, wearing, wielding, items))
    end

    test "displays wielding", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wielding/, Items.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Shield{\/item} in your left hand/, Items.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Short Sword{\/item} in your right hand/, Items.inventory(currency, wearing, wielding, items))
    end

    test "displays wearing", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wearing/, Items.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Leather Armor{\/item} on your chest/, Items.inventory(currency, wearing, wielding, items))
    end

    test "displays items", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are holding:/, Items.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {item}Potion x2{\/item}/, Items.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {item}Dagger{\/item}/, Items.inventory(currency, wearing, wielding, items))
    end
  end
end
