defmodule Game.Command.WearTest do
  use ExVenture.CommandCase

  alias Data.Save
  alias Game.Command
  alias Game.Command.Wear

  doctest Wear

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, level: 1, name: "Leather Chest", keywords: ["chest"], type: "armor", stats: %{slot: :chest}})
    insert_item(%{id: 2, level: 1, name: "Mail Chest", keywords: [], type: "armor", stats: %{slot: :chest}})
    insert_item(%{id: 3, level: 1, name: "Axe", keywords: [], type: "weapon"})
    insert_item(%{id: 4, level: 2, name: "Plate Chest", keywords: [], type: "armor", stats: %{slot: :chest}})

    {:ok, %{state: session_state(%{})}}
  end

  describe "wearing" do
    test "wearing armor", %{state: state} do
      instance = item_instance(1)
      save = %Save{level: 1, items: [instance], wearing: %{}}

      {:update, state} = Command.Wear.run({:wear, "chest"}, %{state | save: save})

      assert state.save.wearing == %{chest: instance}
      assert state.save.items == []

      assert_socket_echo "you are now wearing"
    end

    test "wearing armor replaces the old set", %{state: state} do
      leather_chest = item_instance(1)
      mail_chest = item_instance(2)

      save = %Save{level: 1, items: [leather_chest], wearing: %{chest: mail_chest}}
      {:update, state} = Command.Wear.run({:wear, "chest"}, %{state | save: save})

      assert state.save.wearing == %{chest: leather_chest}
      assert state.save.items == [mail_chest]

      assert_socket_echo "you are now wearing"
    end

    test "wearing only armor", %{state: state} do
      save = %Save{level: 1, items: [item_instance(1), item_instance(3)]}

      :ok = Command.Wear.run({:wear, "axe"}, %{state | save: save})

      assert_socket_echo "cannot wear"
    end

    test "wearing armor - cannot wear higher level armor", %{state: state} do
      instance = item_instance(4)
      save = %Save{level: 1, items: [instance], wearing: %{}}

      :ok = Command.Wear.run({:wear, "plate chest"}, %{state | save: save})

      assert_socket_echo "cannot wear"
    end

    test "item not found", %{state: state} do
      save = %Save{items: [item_instance(1)]}

      :ok = Command.Wear.run({:wear, "bracer"}, %{state | save: save})

      assert_socket_echo "could not be found"
    end
  end

  describe "remove" do
    test "removing armor", %{state: state} do
      leather_chest = item_instance(1)

      save = %Save{items: [], wearing: %{chest: leather_chest}}
      {:update, state} = Command.Wear.run({:remove, "chest"}, %{state | save: save})

      assert state.save.wearing == %{}
      assert state.save.items == [leather_chest]

      assert_socket_echo "you removed"
    end

    test "does not fail when removing a slot that is empty", %{state: state} do
      save = %Save{items: [item_instance(1)], wearing: %{}}
      :ok = Command.Wear.run({:remove, "chest"}, %{state | save: save})

      assert_socket_echo "nothing was on your chest"
    end

    test "unknown slot", %{state: state} do
      save = %Save{items: [item_instance(1)], wearing: %{}}
      :ok = Command.Wear.run({:remove, "hair"}, %{state | save: save})

      assert_socket_echo "unknown armor slot"
    end
  end

  describe "removing from wearing map" do
    test "removes from wearing and adds to item list" do
      chest_piece = item_instance(1)
      other_item = item_instance(2)

      assert {%{}, [^chest_piece, ^other_item]} = Wear.remove(:chest, %{chest: chest_piece}, [other_item])
    end
  end
end
