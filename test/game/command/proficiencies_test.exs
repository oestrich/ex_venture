defmodule Game.Command.ProficienciesTest do
  use Data.ModelCase

  alias Data.Proficiency
  alias Game.Command.Proficiencies

  doctest Proficiencies

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()

    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    start_and_clear_proficiencies()
    proficiency = create_proficiency(%{name: "Swimming"})
    insert_proficiency(proficiency)

    save = %{character.save | proficiencies: [%Proficiency.Instance{proficiency_id: proficiency.id, points: 10}]}

    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "view all proficiencies" do
    test "view the version", %{state: state} do
      :ok = Proficiencies.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Swimming), echo)
    end
  end
end
