defmodule Web.HelpTopicTest do
  use Data.ModelCase

  alias Game.Help.Agent, as: HelpAgent
  alias Web.HelpTopic

  test "creating a new help topic updates the agent" do
    start_and_clear_help()

    params = %{
      "name" => "Fighter",
      "keywords" => "fighter,class",
      "body" => "This class uses physical skills",
    }

    HelpTopic.create(params)

    assert HelpAgent.topics() |> length() == 1
  end

  test "updating a help topic updates the agent" do
    help_topic = create_help_topic(%{
      name: "Fighter",
      keywords: ["fighter", "class"],
      body: "This class uses physical skills",
    })

    start_and_clear_help()

    HelpTopic.update(help_topic.id, %{name: "Barbarian"})

    [bararbian | _] = HelpAgent.topics()
    assert bararbian.name == "Barbarian"
  end
end
