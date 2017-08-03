defmodule Game.Command.WieldTest do
  use Data.ModelCase
  doctest Game.Command.Wield

  alias Data.Save
  alias Game.Command
  alias Game.Items

  @socket Test.Networking.Socket

  setup do
    Items.start_link
    Agent.update(Items, fn (_) ->
      %{
        1 => %{id: 1, name: "Sword", keywords: [], type: "weapon"},
        2 => %{id: 2, name: "Axe", keywords: [], type: "weapon"},
        3 => %{id: 2, name: "Potion", keywords: [], type: "basic"},
      }
    end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  describe "wielding" do
    test "wield an item", %{session: session, socket: socket} do
      save = %Save{item_ids: [1], wielding: %{}}
      {:update, state} = Command.Wield.run({:wield, "sword"}, session, %{socket: socket, save: save})

      assert state.save.wielding == %{right: 1}
      assert state.save.item_ids == []

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Sword is now in your right hand), look)
    end

    test "can only wield a weapon", %{session: session, socket: socket} do
      save = %Save{item_ids: [3]}
      :ok = Command.Wield.run({:wield, "potion"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Potion cannot be wielded), look)
    end

    test "wield an item - puts current item back in inventory", %{session: session, socket: socket} do
      save = %Save{wielding: %{right: 1}, item_ids: [2]}
      {:update, state} = Command.Wield.run({:wield, "axe"}, session, %{socket: socket, save: save})

      assert state.save.wielding == %{right: 2}
      assert state.save.item_ids == [1]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Axe is now in your right hand), look)
    end

    test "item not found", %{session: session, socket: socket} do
      save = %Save{item_ids: [1]}
      Command.Wield.run({:wield, "polearm"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r("polearm" could not be found), look)
    end
  end

  describe "unwielding" do
    test "unwield right hand", %{session: session, socket: socket} do
      save = %Save{wielding: %{right: 1}, item_ids: []}
      {:update, state} = Command.Wield.run({:unwield, "right"}, session, %{socket: socket, save: save})

      assert state.save.wielding == %{}
      assert state.save.item_ids == [1]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Your right hand is now empty), look)
    end

    test "unwield left hand", %{session: session, socket: socket} do
      save = %Save{wielding: %{left: 1}, item_ids: []}
      {:update, state} = Command.Wield.run({:unwield, "left"}, session, %{socket: socket, save: save})

      assert state.save.wielding == %{}
      assert state.save.item_ids == [1]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Your left hand is now empty), look)
    end

    test "unknown hand", %{session: session, socket: socket} do
      save = %Save{wielding: %{left: 1}, item_ids: []}
      :ok = Command.Wield.run({:unwield, "down"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Unknown hand), look)
    end
  end
end
