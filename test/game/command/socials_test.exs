defmodule Game.Command.SocialsTest do
  use ExVenture.CommandCase

  import Test.SocialsHelper

  alias Data.Social
  alias Game.Command.Socials

  doctest Socials

  setup do
    start_and_clear_socials()

    %Social{
      id: 1,
      name: "Smile",
      command: "smile",
      with_target: "[user] smiles at [target]",
      without_target: "[user] smiles"
    } |> insert_social()
    %Social{id: 2, name: "Laugh", command: "laugh"} |> insert_social()

    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)
    %{state: session_state(%{user: user, character: character, save: character.save})}
  end

  describe "list out all socials" do
    test "a paginated response", %{state: state} do
      {:paginate, echo, _state} = Socials.run({:list}, state)

      assert Regex.match?(~r/Smile/, echo)
    end
  end

  describe "view a single social" do
    test "social is found", %{state: state} do
      :ok = Socials.run({:help, "smile"}, state)

      assert_socket_echo "smile"
    end

    test "social is not found", %{state: state} do
      :ok = Socials.run({:help, "wave"}, state)

      assert_socket_echo "could not be found"
    end
  end

  describe "parsing socials" do
    test "social found with target" do
      assert {"smile", "guard"} = Socials.parse("smile guard")
    end

    test "social not found with target" do
      assert {:error, :bad_parse, "chat guard"} = Socials.parse("chat guard")
    end

    test "social found without target" do
      assert {"smile"} = Socials.parse("smile")
    end

    test "social not found without target" do
      assert {:error, :bad_parse, "chat"} = Socials.parse("chat")
    end
  end

  describe "using a social" do
    test "with a target", %{state: state} do
      guard = create_npc(%{name: "Guard"})
      start_room(%{npcs: [guard]})

      :ok = Socials.run({"smile", "guard"}, state)

      assert_socket_echo "smiles at"
    end

    test "with a target - target not found", %{state: state} do
      start_room(%{})

      :ok = Socials.run({"smile", "guard"}, state)

      assert_socket_echo "could not be"
    end

    test "without a target", %{state: state} do
      :ok = Socials.run({"smile"}, state)

      assert_socket_echo "smiles"
    end
  end
end
