defmodule Data.SaveTest do
  use ExUnit.Case
  import TestHelpers

  alias Data.Save
  alias Data.Save.Validations

  doctest Data.Save
  doctest Data.Save.Validations

  describe "loading" do
    test "converts strings to atoms as keys" do
      {:ok, save} = Data.Save.load(%{"room_id" => 1})
      assert save.room_id == 1
    end

    test "loads and migrates stats" do
      save = %{
        "stats" => %{
          "health" => 50,
          "max_health" => 50,
          "strength" => 10,
          "dexterity" => 10,
          "constitution" => 10,
          "wisdom" => 10,
          "move_points" => 20,
          "max_move_points" => 20,
        },
      }

      {:ok, %Data.Save{stats: stats}} = Data.Save.load(save)

      assert stats.health_points == 50
      assert stats.max_health_points == 50
      assert stats.strength == 10
      assert stats.agility == 10
      assert stats.awareness == 10
      assert stats.vitality == 10
      assert stats.willpower == 10
      assert stats.endurance_points == 20
      assert stats.max_endurance_points == 20
    end

    test "loads wearing" do
      {:ok, %Data.Save{wearing: %{chest: chest}}} = Data.Save.load(%{"wearing" => %{"chest" => 1}})
      assert chest.id == 1
    end

    test "loads wielding" do
      {:ok, %{wielding: %{right: right}}} = Data.Save.load(%{"wielding" => %{"right" => 1}})
      assert right.id == 1
    end
  end

  test "ensures channels is always an array when loading" do
    {:ok, save} = Save.load(%{})
    assert save.channels == []
  end
end
