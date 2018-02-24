defmodule Web.SocialTest do
  use Data.ModelCase
  import Test.SkillsHelper

  alias Game.Socials
  alias Web.Social

  setup do
    start_and_clear_skills()
  end

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

    assert Socials.social("smile").name == "Smile"
  end

  test "updating a social" do
    social = create_social(%{name: "Smile"})

    {:ok, social} = Social.update(social, %{name: "Laugh", command: "laugh"})

    assert social.name == "Laugh"

    assert is_nil(Socials.social("smile"))
    assert Socials.social("laugh").name == "Laugh"
  end
end
