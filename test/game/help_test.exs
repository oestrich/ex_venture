defmodule Game.HelpTest do
  use ExUnit.Case
  doctest Game.Help

  alias Game.Help

  test "loading a help topic" do
    assert Regex.match?(~r(Example:), Help.topic("say"))
  end

  test "loading a help topic from an alias" do
    assert Regex.match?(~r(Example:), Help.topic("inv"))
  end

  test "loading a help topic from a command" do
    assert Regex.match?(~r(Example:), Help.topic("global"))
  end

  test "loading a help topic - unknown" do
    assert Help.topic("unknown") == "Unknown topic"
  end
end
