defmodule VMLTest do
  use ExUnit.Case

  doctest VML

  describe "parsing simple text" do
    test "just strings" do
      {:ok, tokens} = VML.parse("hi there")

      assert tokens == [string: "hi there"]
    end

    test "simple tag" do
      {:ok, tokens} = VML.parse("{red}hi there{/red}")

      assert tokens == [{:tag, [name: "red"], [string: "hi there"]}]
    end

    test "tag in a tag" do
      {:ok, tokens} = VML.parse("{say}hi there {npc}Guard{/npc}{/say}")

      assert tokens == [{:tag, [name: "say"], [{:string, "hi there "}, {:tag, [name: "npc"], [string: "Guard"]}]}]
    end

    test "a template variable" do
      {:ok, tokens} = VML.parse("hello [name]")

      assert tokens == [{:string, "hello "}, {:variable, "name"}]
    end

    test "a resource variable" do
      {:ok, tokens} = VML.parse("welcome to {{zone:1}}")

      assert tokens == [{:string, "welcome to "}, {:resource, "zone", "1"}]
    end
  end
end
