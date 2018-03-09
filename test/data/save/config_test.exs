defmodule Data.Save.ConfigTest do
  use ExUnit.Case
  doctest Data.Save.Config

  alias Data.Save.Config

  describe "is a configuration option" do
    test "prompt is" do
      assert Config.option?("prompt")
      assert Config.option?(:prompt)
    end

     test "hints is" do
      assert Config.option?("hints")
      assert Config.option?(:hints)
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
  end
end
