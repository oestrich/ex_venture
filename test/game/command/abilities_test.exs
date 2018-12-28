defmodule Game.Command.AbilitiesTest do
  use Data.ModelCase

  alias Data.Ability
  alias Data.Save
  alias Game.Command.Abilities

  doctest Abilities

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()

    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    start_and_clear_abilities()
    ability = create_ability(%{name: "Swimming"})
    insert_ability(ability)

    save = %{character.save | abilities: [%Ability.Instance{ability_id: ability.id, points: 10}]}

    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "view all abilities" do
    test "view the version", %{state: state} do
      :ok = Abilities.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Swimming), echo)
    end
  end
end
