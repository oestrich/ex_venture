defmodule Game.CommandTest do
  use ExUnit.Case

  alias Game.Command

  test "parsing say" do
    assert Command.parse("say hello") == {:say, "hello"}
  end

  test "parsing who is online" do
    assert Command.parse("who is online") == {:who}
    assert Command.parse("who") == {:who}
  end

  test "quitting" do
    assert Command.parse("quit") == {:quit}
  end

  test "command not found" do
    assert Command.parse("does not exist") == {:error, :bad_parse}
  end
end
