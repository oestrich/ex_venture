defmodule Game.HelpTest do
  use Data.ModelCase

  doctest Game.Help

  alias Game.Help

  test "loading a help topic" do
    assert Regex.match?(~r(Example:), Help.topic("say"))
  end

  test "loading a help topic from an alias" do
    assert Regex.match?(~r(View your inventory), Help.topic("inv"))
  end

  test "loading a help topic from a command" do
    assert Regex.match?(~r(channels), Help.topic("channels"))
  end

  test "loading a help topic - unknown" do
    assert Help.topic("unknown") == "Unknown topic"
  end

  test "loading a topic from the database" do
    topic = create_help_topic(%{name: "The World", keywords: ["world"], body: "It is a world"})
    Agent.update(Help.Agent, fn (_) -> %{database: [topic]} end)

    assert Regex.match?(~r(world), Help.topic("world"))
  end

  test "loading help from proficiencies" do
    start_and_clear_proficiencies()

    create_proficiency(%{name: "Swimming", description: "Swim to places."})
    |> insert_proficiency()

    assert Regex.match?(~r(Swim), Help.topic("swimming"))
  end

  test "load built in help files" do
    Help.Agent.reset()
    assert Regex.match?(~r(target), Help.topic("combat"))
  end
end
