defmodule Game.Format.ResourcesTest do
  use ExUnit.Case

  import Test.ItemsHelper

  alias Game.Format.Resources

  setup do
    start_and_clear_items()
  end

  describe "parsing nouns" do
    test "items" do
      sword = %{id: 1, name: "Sword"}
      insert_item(sword)

      assert Resources.parse("Here is my [[item:1]]") == "Here is my {item}Sword{/item}"
    end
  end
end
