defmodule Game.Format.TemplateTest do
  use ExUnit.Case
  doctest Game.Format.Template

  alias Game.Format.Template

  test "simple template" do
    assert Template.render("[name]", %{name: "Player"}) == "Player"
  end

  describe "variable can include spaces" do
    test "includes the space" do
      assert Template.render("[ name]", %{name: "Player"}) == " Player"
    end

    test "includes newlines" do
      assert Template.render("[\nname]", %{name: "Player"}) == "\nPlayer"
    end

    test "if key not found skips the space" do
      assert Template.render("[ name]", %{}) == ""
    end

    test "if key not found skips newlines" do
      assert Template.render("[\nname]", %{}) == ""
    end

    test "empty strings are considered 'nil'" do
      assert Template.render("[\nname]", %{name: ""}) == ""
    end
  end

  test "nil variables are treated as empty" do
    string =
      ~s(You say[ adverb_phrase], {say}"[message]"{/say})
      |> Template.render(%{
        message: "Hello",
        adverb_phrase: nil,
      })

    assert string == "You say, {say}\"Hello\"{/say}"
  end
end
