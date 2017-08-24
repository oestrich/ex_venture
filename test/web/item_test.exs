defmodule Web.ItemTest do
  use ExUnit.Case

  alias Web.Item

  describe "parsing params properly" do
    test "splits keywords into an array" do
      assert Item.cast_params(%{"keywords" => "sword, rapier"})["keywords"] == ["sword", "rapier"]
    end

    test "parses stats" do
      assert Item.cast_params(%{"stats" => ~s({"slot":"chest"})})["stats"] == %{slot: :chest}
    end

    test "parses stats - bad json" do
      assert Item.cast_params(%{"stats" => ~s({"slot":"ches)})["stats"] == ~s({"slot":"ches)
    end

    test "parses effects" do
      effects = [%{kind: "damage", type: :arcane, amount: 10}]
      assert Item.cast_params(%{"effects" => ~s([{"kind":"damage","type":"arcane","amount":10}])})["effects"] == effects
    end

    test "parses effects - bad json" do
      assert Item.cast_params(%{"effects" => ~s({"slot":"ches)})["effects"] == ~s({"slot":"ches)
    end
  end
end
