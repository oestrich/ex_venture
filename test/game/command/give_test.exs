defmodule Game.Command.GiveTest do
  use ExVenture.CommandCase

  alias Game.Command.Give

  doctest Give

  @room Test.Game.Room

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)
    %{state: session_state(%{user: user, character: character, save: character.save})}
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

      assert_socket_echo "could not be found"
    end

    test "not enough currency", %{state: state} do
      :ok = Give.run({"100 gold", :to, "player"}, state)

      assert_socket_echo "do not have enough gold"
    end

    test "character not found", %{state: state} do
      :ok = Give.run({"potion", :to, "bandit"}, state)

      assert_socket_echo "could not be found"
    end
  end
end
