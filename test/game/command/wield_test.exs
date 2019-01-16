defmodule Game.Command.WieldTest do
  use ExVenture.CommandCase

  alias Data.Save
  alias Game.Command.Wield

  doctest Game.Command.Wield

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, level: 1, name: "Sword", keywords: [], type: "weapon"})
    insert_item(%{id: 2, level: 1, name: "Axe", keywords: [], type: "weapon"})
    insert_item(%{id: 3, level: 1, name: "Potion", keywords: [], type: "basic"})
    insert_item(%{id: 4, level: 2, name: "Long Sword", keywords: [], type: "weapon"})

    %{state: session_state(%{})}
  end

  describe "wielding" do
    test "wield an item", %{state: state} do
      sword = item_instance(1)
      save = %Save{level: 1, items: [sword], wielding: %{}}
      {:update, state} = Wield.run({:wield, "sword"}, %{state | save: save})

      assert state.save.wielding == %{right: sword}
      assert state.save.items == []

      assert_socket_echo "is now in your right"
    end

    test "can only wield a weapon", %{state: state} do
      save = %Save{level: 1, items: [item_instance(3)]}
      :ok = Wield.run({:wield, "potion"}, %{state | save: save})

      assert_socket_echo "cannot be wielded"
    end

    test "wield an item - puts current item back in inventory", %{state: state} do
      sword = item_instance(1)
      axe = item_instance(2)

      save = %Save{level: 1, wielding: %{right: sword}, items: [axe]}
      {:update, state} = Wield.run({:wield, "axe"}, %{state | save: save})

      assert state.save.wielding == %{right: axe}
      assert state.save.items == [sword]

      assert_socket_echo "is now in your right"
    end

    test "wield an item in other hand - puts current item back in inventory", %{state: state} do
      sword = item_instance(1)
      axe = item_instance(2)

      save = %Save{level: 1, wielding: %{left: sword}, items: [axe]}
      {:update, state} = Wield.run({:wield, "axe"}, %{state | save: save})

      assert state.save.wielding == %{right: axe}
      assert state.save.items == [sword]

      assert_socket_echo "is now in your right"
    end

    test "cannot wield higher level weapons", %{state: state} do
      instance = item_instance(4)
      save = %Save{level: 1, items: [instance], wearing: %{}}
      :ok = Wield.run({:wield, "long sword"}, %{state | save: save})

      assert_socket_echo "cannot wield"
    end

    test "item not found", %{state: state} do
      save = %Save{level: 1, items: [item_instance(1)]}
      Wield.run({:wield, "polearm"}, %{state | save: save})

      assert_socket_echo "could not be found"
    end
  end

  describe "unwielding" do
    test "unwield right hand", %{state: state} do
      sword = item_instance(1)
      save = %Save{wielding: %{right: sword}, items: []}
      {:update, state} = Wield.run({:unwield, "right"}, %{state | save: save})

      assert state.save.wielding == %{}
      assert state.save.items == [sword]

      assert_socket_echo "right hand is now empty"
    end

    test "unwield left hand", %{state: state} do
      sword = item_instance(1)
      save = %Save{wielding: %{left: sword}, items: []}
      {:update, state} = Wield.run({:unwield, "left"}, %{state | save: save})

      assert state.save.wielding == %{}
      assert state.save.items == [sword]

      assert_socket_echo "left hand is now empty"
    end

    test "unknown hand", %{state: state} do
      save = %Save{wielding: %{left: item_instance(1)}, items: []}
      :ok = Wield.run({:unwield, "down"}, %{state | save: save})

      assert_socket_echo "unknown hand"
    end
  end
end
