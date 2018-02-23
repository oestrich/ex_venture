defmodule Web.SocialTest do
  use Data.ModelCase

  alias Web.Social

  test "creating a social" do
    params = %{
      "name" => "Smile",
      "command" => "smile",
      "with_target" => "{user} smile at {target}",
      "without_target" => "{user} smiles",
    }

    {:ok, social} = Social.create(params)

    assert social.name == "Smile"
    assert social.command == "smile"
  end

  test "updating a social" do
    social = create_social(%{name: "Smile"})

    {:ok, social} = Social.update(social, %{name: "Laugh"})

    assert social.name == "Laugh"
  end
end
