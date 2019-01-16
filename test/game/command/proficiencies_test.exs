defmodule Game.Command.ProficienciesTest do
  use ExVenture.CommandCase

  alias Data.Proficiency
  alias Game.Command.Proficiencies

  doctest Proficiencies

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    start_and_clear_proficiencies()
    proficiency = create_proficiency(%{name: "Swimming"})
    insert_proficiency(proficiency)

    save = %{character.save | proficiencies: [%Proficiency.Instance{id: proficiency.id, ranks: 10}]}

    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "view all proficiencies" do
    test "view the version", %{state: state} do
      :ok = Proficiencies.run({}, state)

      assert_socket_echo "swimming"
    end
  end
end
