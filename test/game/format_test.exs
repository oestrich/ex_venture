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

    test "wraps at 80 chars - ignores {color} codes when counting" do
      line = "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps at 80 chars - ignores {command} codes when counting" do
      line =
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps and does not chuck newlines" do
      assert Format.wrap("hi\nthere") == "hi\nthere"
      assert Format.wrap("hi\n\n\nthere") == "hi\n\n\nthere"
    end
  end
end
