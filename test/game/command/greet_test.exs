defmodule Game.Command.GreetTest do
  use Data.ModelCase
  doctest Game.Command.Greet

  alias Game.Command.Greet

  @room Test.Game.Room
  @npc Test.Game.NPC
  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages

    user = create_user(%{name: "user", password: "password"})

    room = %{
      id: 1,
      npcs: [npc_attributes(%{id: 1, name: "Guard"})],
      players: [user_attributes(%{id: 1, name: "Player"})],
    }
    @room.set_room(Map.merge(@room._room(), room))

    %{state: %{socket: :socket, user: user, save: %{room_id: room.id}}}
  end

  describe "greet an NPC" do
    setup do
      @npc.clear_greets()
    end

    test "npc present", %{state: state} do
      :ok = Greet.run({:greet, "guard"}, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(greet {yellow}Guard{/yellow}), mail)

      assert @npc.get_greets() == [{1, state.user}]
    end
  end

  describe "greet a player" do
    test "player present", %{state: state} do
      :ok = Greet.run({:greet, "player"}, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(greet {blue}Player{/blue}), mail)
    end
  end
end
