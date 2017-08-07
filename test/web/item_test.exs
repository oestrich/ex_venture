defmodule Web.ItemTest do
  use ExUnit.Case

  alias Web.Item

  describe "parsing params properly" do
    test "splits keywords into an array" do
      assert Item.cast_params(%{"keywords" => "sword, rapier"})["keywords"] == ["sword", "rapier"]
    end

    test "inserts effects for now" do
      assert Item.cast_params(%{})["effects"] == []
    end

    test "parses stats" do
      assert Item.cast_params(%{"stats" => ~s({"slot":"chest"})})["stats"] == %{slot: :chest}
    end

    test "parses stats - bad json" do
      assert Item.cast_params(%{"stats" => ~s({"slot":"ches)})["stats"] == ~s({"slot":"ches)
    end
  end
end
