defmodule Game.MessageTest do
  use ExUnit.Case

  alias Game.Message

  describe "simple message formatting" do
    test "capitalizes the first character" do
      assert Message.format("hi.") == "Hi."
      assert Message.format("Hi.") == "Hi."
    end

    test "adds punctuation if required" do
      assert Message.format("Hi") == "Hi."
      assert Message.format("Hi!") == "Hi!"
    end
  end
end
