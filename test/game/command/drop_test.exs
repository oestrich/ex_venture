defmodule Game.Command.DropTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Save
  alias Game.Items

  setup do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => %{id: 1, name: "Sword", keywords: []}} end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "drop an item in a room", %{session: session, socket: socket} do
    @room.clear_drops()

    state = %{socket: socket, user: %{name: "user"}, save: %Save{room_id: 1, item_ids: [1]}}
    {:update, state} = Game.Command.Drop.run({"sword"}, session, state)

    assert state.save.item_ids |> length == 0

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You dropped), look)

    assert [{1, {:user, _}, %{id: 1}}] = @room.get_drops()
  end

  test "item not found in your inventory", %{session: session, socket: socket} do
    :ok = Game.Command.Drop.run({"sword"}, session, %{socket: socket, save: %Save{room_id: 1, item_ids: [2]}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Could not find), look)
  end
end
