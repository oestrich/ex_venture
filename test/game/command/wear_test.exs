defmodule Game.Command.WearTest do
  use Data.ModelCase
  doctest Game.Command.Wear

  alias Data.Save
  alias Game.Command
  alias Game.Items

  @socket Test.Networking.Socket

  setup do
    Items.start_link
    Agent.update(Items, fn (_) ->
      %{
        1 => %{id: 1, name: "Leather Chest", keywords: ["chest"], type: "armor", stats: %{slot: :chest}},
        2 => %{id: 1, name: "Mail Chest", keywords: [], type: "armor", stats: %{slot: :chest}},
        3 => %{id: 2, name: "Axe", keywords: [], type: "weapon"},
      }
    end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  describe "wearing" do
    test "wearing armor", %{session: session, socket: socket} do
      save = %Save{item_ids: [1]}
      {:update, state} = Command.Wear.run({:wear, "chest"}, session, %{socket: socket, save: save})

      assert state.save.wearing == %{chest: 1}
      assert state.save.item_ids == []

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You are now wearing Leather Chest), look)
    end

    test "wearing armor replaces the old set", %{session: session, socket: socket} do
      save = %Save{item_ids: [1], wearing: %{chest: 2}}
      {:update, state} = Command.Wear.run({:wear, "chest"}, session, %{socket: socket, save: save})

      assert state.save.wearing == %{chest: 1}
      assert state.save.item_ids == [2]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You are now wearing Leather Chest), look)
    end

    test "wearing only armor", %{session: session, socket: socket} do
      save = %Save{item_ids: [1, 3]}
      :ok = Command.Wear.run({:wear, "axe"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You cannot wear Axe), look)
    end

    test "item not found", %{session: session, socket: socket} do
      save = %Save{item_ids: [1]}
      :ok = Command.Wear.run({:wear, "bracer"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r("bracer" could not be found), look)
    end
  end

  describe "remove" do
    test "removing armor", %{session: session, socket: socket} do
      save = %Save{item_ids: [], wearing: %{chest: 1}}
      {:update, state} = Command.Wear.run({:remove, "chest"}, session, %{socket: socket, save: save})

      assert state.save.wearing == %{}
      assert state.save.item_ids == [1]

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You removed Leather Chest from your chest), look)
    end

    test "does not fail when removing a slot that is empty", %{session: session, socket: socket} do
      save = %Save{item_ids: [1], wearing: %{}}
      :ok = Command.Wear.run({:remove, "chest"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Nothing was on your chest.), look)
    end

    test "unknown slot", %{session: session, socket: socket} do
      save = %Save{item_ids: [1], wearing: %{}}
      :ok = Command.Wear.run({:remove, "finger"}, session, %{socket: socket, save: save})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Unknown armor slot), look)
    end
  end
end
