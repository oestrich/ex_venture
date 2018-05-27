defmodule Game.Command.LookTest do
  use Data.ModelCase
  doctest Game.Command.Look

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Item
  alias Game.Command.Look

  setup do
    start_and_clear_items()
    item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
    insert_item(item)

    room = %{
      items: [Item.instantiate(item)],
      npcs: [npc_attributes(%{id: 1, name: "Bandit", description: "bandit description"})],
      players: [user_attributes(%{id: 1, name: "Player"})],
      features: [%{key: "log", short_description: "log", description: "a log"}],
      zone: %{id: 10, name: "Zone"}
    }
    @room.set_room(Map.merge(@room._room(), room))

    @socket.clear_messages

    {:ok, %{socket: :socket}}
  end

  test "view room information", %{socket: socket} do
    :ok = Look.run({}, %{socket: socket, user: %{id: 10}, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
    assert Regex.match?(~r(Exits), look)
    assert Regex.match?(~r(Items), look)

    assert Enum.any?(@socket.get_push_gmcps(), fn ({_socket, module, _}) -> module == "Zone.Map" end)
  end

  test "view room information - the room is offline", %{socket: socket} do
    @room.set_room(:offline)

    {:error, :room_offline} = Look.run({}, %{socket: socket, user: %{id: 10}, save: %{room_id: 1}})

    assert @socket.get_echos() == []
  end

  test "looking at an item", %{socket: socket} do
    :ok = Look.run({:other, "short sword"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(A simple blade), look)
  end

  test "looking at an npc", %{socket: socket} do
    :ok = Look.run({:other, "bandit"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(bandit description), look)
  end

  test "looking at a player", %{socket: socket} do
    :ok = Look.run({:other, "player"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Player), look)
  end

  test "looking in a direction", %{socket: socket} do
    :ok = Look.run({:direction, "north"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
  end

  test "looking at a room feature", %{socket: socket} do
    :ok = Look.run({:other, "log"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(a log), look)
  end

  test "could not find the name", %{socket: socket} do
    :ok = Look.run({:other, "unknown"}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Could not find), look)
  end
end
