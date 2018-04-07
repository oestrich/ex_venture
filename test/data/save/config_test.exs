defmodule Data.Save.ConfigTest do
  use ExUnit.Case
  doctest Data.Save.Config

  alias Data.Save.Config
  alias Game.ColorCodes

  describe "is a configuration option" do
    test "prompt is" do
      assert Config.option?("prompt")
      assert Config.option?(:prompt)
    end

    test "hints is" do
      assert Config.option?("hints")
      assert Config.option?(:hints)
    end

    test "pager_size is" do
      assert Config.option?("pager_size")
      assert Config.option?(:pager_size)
    end

    test "color config is" do
      assert Config.option?("color_npc")
      assert Config.option?(:color_npc)
    end

    test "unknown is not" do
      refute Config.option?("unknown")
      refute Config.option?(:unknown)
    end
  end

  describe "settable configuration" do
    test "prompt is settable" do
      assert Config.settable?("prompt")
      assert Config.settable?(:prompt)
    end

    test "hint is not settable" do
      refute Config.settable?("hint")
      refute Config.settable?(:hint)
    end

    test "pager_size is settable" do
      assert Config.settable?("pager_size")
      assert Config.settable?(:pager_size)
    end

    test "color config is settable" do
      assert Config.settable?("color_npc")
      assert Config.settable?(:color_npc)
    end
  end

  describe "cast configuration" do
    test "casting prompt" do
      assert Config.cast_config("prompt", "%h/%H") == {:ok, "%h/%H"}
    end

    test "casting pager_size" do
      assert Config.cast_config("pager_size", "20") == {:ok, 20}
      assert Config.cast_config("pager_size", "not a number") == :error
    end

    test "casting non-settable config" do
      assert Config.cast_config("hint", "true") == {:error, :bad_config}
    end

    test "casting a color value" do
      assert Config.cast_config("color_npc", "green") == {:ok, "green"}

      ColorCodes.insert(%{key: "pink"})
      assert Config.cast_config("color_npc", "pink") == {:ok, "pink"}
    end
  end

  describe "color config" do
    test "true for valid tags" do
      assert Config.color_config?("color_npc")
      assert Config.color_config?("color_quest")
    end

    test "false for invalid tags" do
      refute Config.color_config?("color_potion")
    end
  end
end
