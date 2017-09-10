defmodule Game.FormatTest do
  use ExUnit.Case
  doctest Game.Format

  alias Game.Format

  describe "line wrapping" do
    test "single line" do
      assert Format.wrap("one line") == "one line"
    end

    test "wraps at 80 chars" do
      assert Format.wrap("this line will be split up into two lines because it is longer than 80 characters") ==
        "this line will be split up into two lines because it is longer than 80\ncharacters"
    end
  end

  describe "inventory formatting" do
    setup do
      wearing = %{chest: %{name: "Leather Armor"}}
      wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      items = [%{name: "Potion"}, %{name: "Dagger"}]

      %{currency: 10, wearing: wearing, wielding: wielding, items: items}
    end

    test "displays currency", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You have 10 gold/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wielding", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wielding/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Shield{\/cyan} in your left hand/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Short Sword{\/cyan} in your right hand/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wearing", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wearing/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {cyan}Leather Armor{\/cyan} on your chest/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays items", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are holding:/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {cyan}Potion{\/cyan}/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {cyan}Dagger{\/cyan}/, Format.inventory(currency, wearing, wielding, items))
    end
  end
end
