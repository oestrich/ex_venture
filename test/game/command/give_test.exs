defmodule Game.Command.GiveTest do
  use Data.ModelCase
  doctest Game.Command.Give

  alias Game.Command.Give

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user, save: user.save}}
  end

  describe "giving items away" do
    setup %{state: state} do
      room = Map.merge(@room._room(), %{
        npcs: [npc_attributes(%{id: 1, name: "Guard"})],
        players: [user_attributes(%{id: 1, name: "Player"})],
      })

      @room.set_room(room)

      start_and_clear_items()
      insert_item(%{id: 1, name: "potion", keywords: []})

      save = %{state.save | items: [item_instance(1)], currency: 50}

      %{state: %{state | save: save}}
    end

    test "give to a player", %{state: state} do
      {:update, state} = Give.run({"potion", :to, "player"}, state)

      assert state.save.items == []
    end

    test "give to an npc", %{state: state} do
      {:update, state} = Give.run({"potion", :to, "guard"}, state)

      assert state.save.items == []
    end

    test "give currency", %{state: state} do
      {:update, state} = Give.run({"40 gold", :to, "player"}, state)

      assert state.save.currency == 10
    end

    test "item not found", %{state: state} do
      :ok = Give.run({"thing", :to, "player"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r[could not be found], echo)
    end

    test "not enough currency", %{state: state} do
      :ok = Give.run({"100 gold", :to, "player"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r[do not have enough gold], echo)
    end

    test "character not found", %{state: state} do
      :ok = Give.run({"potion", :to, "bandit"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r[could not be found], echo)
    end
  end
end
