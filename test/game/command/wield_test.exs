defmodule Game.Command.WieldTest do
  use Data.ModelCase
  doctest Game.Command.Wield

  alias Data.Save
  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, level: 1, name: "Sword", keywords: [], type: "weapon"})
    insert_item(%{id: 2, level: 1, name: "Axe", keywords: [], type: "weapon"})
    insert_item(%{id: 3, level: 1, name: "Potion", keywords: [], type: "basic"})
    insert_item(%{id: 4, level: 2, name: "Long Sword", keywords: [], type: "weapon"})

    @socket.clear_messages
    {:ok, %{socket: :socket}}
  end

  describe "wielding" do
    test "wield an item", %{socket: socket} do
      sword = item_instance(1)
      save = %Save{level: 1, items: [sword], wielding: %{}}
      {:update, state} = Command.Wield.run({:wield, "sword"}, %{socket: socket, save: save})

      assert state.save.wielding == %{right: sword}
      assert state.save.items == []

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Sword is now in your right hand), look)
    end

    test "can only wield a weapon", %{socket: socket} do
      save = %Save{level: 1, items: [item_instance(3)]}
      :ok = Command.Wield.run({:wield, "potion"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Potion cannot be wielded), look)
    end

    test "wield an item - puts current item back in inventory", %{socket: socket} do
      sword = item_instance(1)
      axe = item_instance(2)

      save = %Save{level: 1, wielding: %{right: sword}, items: [axe]}
      {:update, state} = Command.Wield.run({:wield, "axe"}, %{socket: socket, save: save})

      assert state.save.wielding == %{right: axe}
      assert state.save.items == [sword]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Axe is now in your right hand), look)
    end

    test "wield an item in other hand - puts current item back in inventory", %{socket: socket} do
      sword = item_instance(1)
      axe = item_instance(2)

      save = %Save{level: 1, wielding: %{left: sword}, items: [axe]}
      {:update, state} = Command.Wield.run({:wield, "axe"}, %{socket: socket, save: save})

      assert state.save.wielding == %{right: axe}
      assert state.save.items == [sword]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Axe is now in your right hand), look)
    end

    test "cannot wield higher level weapons", %{socket: socket} do
      instance = item_instance(4)
      save = %Save{level: 1, items: [instance], wearing: %{}}
      :ok = Command.Wield.run({:wield, "long sword"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You cannot wield), look)
    end

    test "item not found", %{socket: socket} do
      save = %Save{level: 1, items: [item_instance(1)]}
      Command.Wield.run({:wield, "polearm"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r("polearm" could not be found), look)
    end
  end

  describe "unwielding" do
    test "unwield right hand", %{socket: socket} do
      sword = item_instance(1)
      save = %Save{wielding: %{right: sword}, items: []}
      {:update, state} = Command.Wield.run({:unwield, "right"}, %{socket: socket, save: save})

      assert state.save.wielding == %{}
      assert state.save.items == [sword]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Your right hand is now empty), look)
    end

    test "unwield left hand", %{socket: socket} do
      sword = item_instance(1)
      save = %Save{wielding: %{left: sword}, items: []}
      {:update, state} = Command.Wield.run({:unwield, "left"}, %{socket: socket, save: save})

      assert state.save.wielding == %{}
      assert state.save.items == [sword]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Your left hand is now empty), look)
    end

    test "unknown hand", %{socket: socket} do
      save = %Save{wielding: %{left: item_instance(1)}, items: []}
      :ok = Command.Wield.run({:unwield, "down"}, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Unknown hand), look)
    end
  end
end
