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

    test "special characters" do
      {:ok, tokens} = VML.parse("=")

      assert tokens == [{:string, "="}]
    end

    test "map colors" do
      {:ok, tokens} = VML.parse("{map:blue}\\[ \\]{/map:blue}")

      assert tokens == [{:tag, [name: "map:blue"], [{:string, "\\[ \\]"}]}]
    end

    test "tag a attribute" do
      {:ok, tokens} = VML.parse("{command send='help say'}Say{/command}")

      assert tokens == [{:tag, [name: "command", attributes: [{"send", "help say"}]], [{:string, "Say"}]}]
    end

    test "tag attributes" do
      {:ok, tokens} = VML.parse("{command send='help say' click='false'}Say{/command}")

      assert tokens == [{:tag, [name: "command", attributes: [{"send", "help say"}, {"click", "false"}]], [{:string, "Say"}]}]
    end
  end
end
