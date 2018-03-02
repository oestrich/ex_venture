defmodule Game.Command.WearTest do
  use Data.ModelCase
  doctest Game.Command.Wear

  alias Data.Save
  alias Game.Command
  alias Game.Command.Wear

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, level: 1, name: "Leather Chest", keywords: ["chest"], type: "armor", stats: %{slot: :chest}})
    insert_item(%{id: 2, level: 1, name: "Mail Chest", keywords: [], type: "armor", stats: %{slot: :chest}})
    insert_item(%{id: 3, level: 1, name: "Axe", keywords: [], type: "weapon"})
    insert_item(%{id: 4, level: 2, name: "Plate Chest", keywords: [], type: "armor", stats: %{slot: :chest}})

    @socket.clear_messages()
    {:ok, %{socket: :socket}}
  end

  describe "wearing" do
    test "wearing armor", %{socket: socket} do
      instance = item_instance(1)
      save = %Save{level: 1, items: [instance], wearing: %{}}
      {:update, state} = Command.Wear.run({:wear, "chest"}, %{socket: socket, save: save})

      assert state.save.wearing == %{chest: instance}
      assert state.save.items == []

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You are now wearing Leather Chest), look)
    end

    test "wearing armor replaces the old set", %{socket: socket} do
      leather_chest = item_instance(1)
      mail_chest = item_instance(2)

      save = %Save{level: 1, items: [leather_chest], wearing: %{chest: mail_chest}}
      {:update, state} = Command.Wear.run({:wear, "chest"}, %{socket: socket, save: save})

      assert state.save.wearing == %{chest: leather_chest}
      assert state.save.items == [mail_chest]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You are now wearing Leather Chest), look)
    end

    test "wearing only armor", %{socket: socket} do
      save = %Save{level: 1, items: [item_instance(1), item_instance(3)]}
      :ok = Command.Wear.run({:wear, "axe"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You cannot wear Axe), look)
    end

    test "wearing armor - cannot wear higher level armor", %{socket: socket} do
      instance = item_instance(4)
      save = %Save{level: 1, items: [instance], wearing: %{}}
      :ok = Command.Wear.run({:wear, "plate chest"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You cannot wear), look)
    end

    test "item not found", %{socket: socket} do
      save = %Save{items: [item_instance(1)]}
      :ok = Command.Wear.run({:wear, "bracer"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r("bracer" could not be found), look)
    end
  end

  describe "remove" do
    test "removing armor", %{socket: socket} do
      leather_chest = item_instance(1)

      save = %Save{items: [], wearing: %{chest: leather_chest}}
      {:update, state} = Command.Wear.run({:remove, "chest"}, %{socket: socket, save: save})

      assert state.save.wearing == %{}
      assert state.save.items == [leather_chest]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You removed Leather Chest from your chest), look)
    end

    test "does not fail when removing a slot that is empty", %{socket: socket} do
      save = %Save{items: [item_instance(1)], wearing: %{}}
      :ok = Command.Wear.run({:remove, "chest"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Nothing was on your chest.), look)
    end

    test "unknown slot", %{socket: socket} do
      save = %Save{items: [item_instance(1)], wearing: %{}}
      :ok = Command.Wear.run({:remove, "hair"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Unknown armor slot), look)
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
