defmodule Game.Command.LookTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Item

  setup do
    start_and_clear_items()
    item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
    insert_item(item)

    room = %{
      items: [Item.instantiate(item)],
      npcs: [npc_attributes(%{id: 1, name: "Bandit", description: "bandit description"})],
    }
    @room.set_room(Map.merge(@room._room(), room))

    @socket.clear_messages

    {:ok, %{session: :session, socket: :socket}}
  end

  test "view room information", %{session: session, socket: socket} do
    Game.Command.Look.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
    assert Regex.match?(~r(Exits), look)
    assert Regex.match?(~r(Items), look)

    assert Enum.any?(@socket.get_push_gmcps(), fn ({_socket, module, _}) -> module == "Zone.Map" end)
  end

  test "looking at an item", %{session: session, socket: socket} do
    Game.Command.Look.run({"short sword"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(A simple blade), look)
  end

  test "looking at an npc", %{session: session, socket: socket} do
    Game.Command.Look.run({"bandit"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(bandit description), look)
  end

  test "looking in a direction", %{session: session, socket: socket} do
    Game.Command.Look.run({"north"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
  end
end
