defmodule Game.Command.TargetTest do
  use Data.ModelCase
  doctest Game.Command.Target

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    npc = %{id: 1, name: "Bandit"}

    room = @room._room()
    |> Map.put(:npcs, [npc])
    |> Map.put(:players, [%{id: 2, name: "Player"}])

    @room.set_room(room)
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "set your target from someone in the room", %{session: session, socket: socket} do
    {:update, state} = Game.Command.Target.run({"bandit"}, session, %{socket: socket, save: %{room_id: 1}})

    assert state.target == {:npc, 1}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look) 
  end

  test "targeting another player", %{session: session, socket: socket} do
    {:update, state} = Game.Command.Target.run({"player"}, session, %{socket: socket, save: %{room_id: 1}})

    assert state.target == {:user, 2}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look) 
  end

  test "target not found", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({"unknown"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(not find), look) 
  end

  test "viewing your target - npc", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({}, session, %{socket: socket, save: %{room_id: 1}, target: {:npc, 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look) 
  end

  test "viewing your target - npc no longer there", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({}, session, %{socket: socket, save: %{room_id: 1}, target: {:npc, 2}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look) 
  end

  test "viewing your target - user", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({}, session, %{socket: socket, save: %{room_id: 1}, target: {:user, 2}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look)
  end

  test "viewing your target - user no longer there", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({}, session, %{socket: socket, save: %{room_id: 1}, target: {:user, 3}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look) 
  end

  test "viewing your target - missing", %{session: session, socket: socket} do
    :ok = Game.Command.Target.run({}, session, %{socket: socket, save: %{room_id: 1}, target: nil})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have a target), look) 
  end
end
