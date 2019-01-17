defmodule Game.Command.GreetTest do
  use ExVenture.CommandCase

  alias Game.Command.Greet

  doctest Greet

  @npc Test.Game.NPC

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    room = %{
      id: 1,
      npcs: [npc_attributes(%{id: 1, name: "Guard"})],
      players: [user_attributes(%{id: 1, name: "Player"})],
    }
    start_room(room)

    save = %{character.save | room_id: room.id}
    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "greet an NPC" do
    setup do
      @npc.clear_greets()
    end

    test "npc present", %{state: state} do
      :ok = Greet.run({:greet, "guard"}, state)

      assert_socket_echo "greet .*Guard"

      assert @npc.get_greets() == [{1, state.character}]
    end
  end

  describe "greet a player" do
    test "player present", %{state: state} do
      :ok = Greet.run({:greet, "player"}, state)

      assert_socket_echo "greet .*Player"
    end
  end
end
