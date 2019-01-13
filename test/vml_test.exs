defmodule VMLTest do
  use ExUnit.Case

  doctest VML

  describe "parsing simple text" do
    test "skipping an already parsed ast" do
      {:ok, tokens} = VML.parse("hi there")
      {:ok, ^tokens} = VML.parse("hi there")
    end

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

      assert tokens == [
               {:tag, [name: "say"],
                [{:string, "hi there "}, {:tag, [name: "npc"], [string: "Guard"]}]}
             ]
    end

    test "a template variable" do
      {:ok, tokens} = VML.parse("hello [name]")

      assert tokens == [{:string, "hello "}, {:variable, "name"}]
    end

    test "a template variable with spaces" do
      {:ok, tokens} = VML.parse("hello [ name]")
      assert tokens == [{:string, "hello "}, {:variable, {:space, " "}, {:name, "name"}}]

      {:ok, tokens} = VML.parse("hello [\nname]")
      assert tokens == [{:string, "hello "}, {:variable, {:space, "\n"}, {:name, "name"}}]

      {:ok, tokens} = VML.parse("hello [name ]")
      assert tokens == [{:string, "hello "}, {:variable, {:name, "name"}, {:space, " "}}]

      {:ok, tokens} = VML.parse("hello [name\n]")
      assert tokens == [{:string, "hello "}, {:variable, {:name, "name"}, {:space, "\n"}}]
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
      {:ok, tokens} = VML.parse("{blue}\\[ \\]{/blue}")

      assert tokens == [{:tag, [name: "blue"], [{:string, "\\[ \\]"}]}]
    end

    test "tag a attribute" do
      {:ok, tokens} = VML.parse("{command send='help say'}Say{/command}")

      assert tokens == [
               {:tag, [name: "command", attributes: [{"send", [{:string, "help say"}]}]],
                [{:string, "Say"}]}
             ]
    end

    test "tag a attribute with a variable" do
      {:ok, tokens} = VML.parse("{command send='help [command]'}Say{/command}")

      assert tokens == [
               {:tag,
                [
                  name: "command",
                  attributes: [{"send", [{:string, "help "}, {:variable, "command"}]}]
                ], [{:string, "Say"}]}
             ]
    end

    test "tag attributes" do
      {:ok, tokens} = VML.parse("{command send='help say' click='false'}Say{/command}")

      assert tokens == [
               {:tag,
                [
                  name: "command",
                  attributes: [{"send", [{:string, "help say"}]}, {"click", [{:string, "false"}]}]
                ], [{:string, "Say"}]}
             ]
    end

    test "links" do
      {:ok, tokens} =
        VML.parse(
          "{link}http://localhost:4000/connection/authorize?id=1eeb44f7-e015-4089-bacc-1a5dc6ec582d{/link}"
        )

      assert tokens == [
               {:tag, [name: "link"],
                [
                  string:
                    "http://localhost:4000/connection/authorize?id=1eeb44f7-e015-4089-bacc-1a5dc6ec582d"
                ]}
             ]
    end

    test "skipping MXP" do
      {:ok, tokens} = VML.parse("<send>{command}Say{/command}</send>")

      assert tokens == [
               {:string, "<send>"},
               {:tag, [name: "command"], [{:string, "Say"}]},
               {:string, "</send>"}
             ]
    end
  end

  describe "collapse AST back to a string" do
    test "simple" do
      string = VML.collapse([{:string, "Hello"}])
      assert string == "Hello"
    end

    test "multiple strings" do
      string = VML.collapse([{:string, "Hello"}, {:string, ", world"}])
      assert string == "Hello, world"
    end

    test "with tags" do
      string = VML.collapse([{:tag, [name: "red"], [{:string, "Hello"}]}])
      assert string == "{red}Hello{/red}"
    end

    test "nested lists" do
      string = VML.collapse([[{:tag, [name: "red"], [{:string, "Hello"}]}], {:string, "World"}])
      assert string == "{red}Hello{/red}World"
    end

    test "tag attribute" do
      string =
        VML.collapse([
          {:tag, [name: "command", attributes: [{"send", [{:string, "help say"}]}]],
           [{:string, "Say"}]}
        ])

      assert string == "{command send='help say'}Say{/command}"
    end

    test "tag attribute with a variable" do
      string =
        VML.collapse([
          {:tag,
           [
             name: "command",
             attributes: [{"send", [{:string, "help "}, {:variable, "command"}]}]
           ], [{:string, "Say"}]}
        ])

      assert string == "{command send='help [command]'}Say{/command}"
    end

    test "tag attributes" do
      string =
        VML.collapse([
          {:tag,
           [
             name: "command",
             attributes: [{"send", [{:string, "help say"}]}, {"click", [{:string, "false"}]}]
           ], [{:string, "Say"}]}
        ])

      assert string == "{command send='help say' click='false'}Say{/command}"
    end
  end
end
