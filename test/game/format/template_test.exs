defmodule Game.Format.TemplateTest do
  use ExUnit.Case
  doctest Game.Format.Template

  import Game.Format.Context, only: [context: 0]

  alias Game.Format.Context
  alias Game.Format.Template

  test "simple template" do
    context = Context.assign(context(), :name, "Player")

    assert Template.render(context, "[name]") == "Player"
  end

  describe "variable can include spaces" do
    setup do
      %{context: %Context{assigns: %{}}}
    end

    test "includes the space", %{context: context} do
      context = Context.assign(context, :name, "Player")

      assert Template.render(context, "[ name]") == " Player"
    end

    test "includes newlines", %{context: context} do
      context = Context.assign(context, :name, "Player")

      assert Template.render(context, "[\nname]") == "\nPlayer"
    end

    test "if key not found skips the space", %{context: context} do
      assert Template.render(context, "[ name]") == ""
    end

    test "if key not found skips newlines", %{context: context} do
      assert Template.render(context, "[\nname]") == ""
    end

    test "empty strings are considered 'nil'", %{context: context} do
      context = Context.assign(context, :name, "")

      assert Template.render(context, "[\nname]") == ""
    end
  end

  describe "rendering a list of values" do
    context = Context.assign_many(context(), :names, ["Player 1", "Player 2"], fn value -> String.upcase(value) end)

    assert Template.render(context, "[names]") == "PLAYER 1\nPLAYER 2"
  end

  test "nil variables are treated as empty" do
    string =
      context()
      |> Context.assign(:message, "Hello")
      |> Context.assign(:adverb_phrase, nil)
      |> Template.render(~s(You say[ adverb_phrase], {say}"[message]"{/say}))

    assert string == "You say, {say}\"Hello\"{/say}"
  end
end
