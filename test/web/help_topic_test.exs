defmodule Web.HelpTopicTest do
  use Data.ModelCase

  alias Game.Help.Agent, as: HelpAgent
  alias Web.HelpTopic

  test "creating a new help topic updates the agent" do
    Agent.update(HelpAgent, fn (_) -> [] end)

    params = %{
      "name" => "Fighter",
      "keywords" => "fighter,class",
      "body" => "This class uses physical skills",
    }

    HelpTopic.create(params)

    assert HelpAgent.all() |> length() == 1
  end

  test "updating a help topic updates the agent" do
    help_topic = create_help_topic(%{
      name: "Fighter",
      keywords: ["fighter", "class"],
      body: "This class uses physical skills",
    })

    Agent.update(HelpAgent, fn (_) -> [help_topic] end)

    HelpTopic.update(help_topic.id, %{name: "Barbarian"})

    [bararbian | _] = HelpAgent.all()
    assert bararbian.name == "Barbarian"
  end
end
