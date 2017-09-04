defmodule Game.Command.TargetTest do
  use Data.ModelCase
  doctest Game.Command.Target

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    npc = %{id: 1, name: "Bandit"}

    room = @room._room()
    |> Map.put(:npcs, [npc])
    |> Map.put(:players, [%{id: 2, name: "Player", save: %{stats: %{health: 1}}}])

    @room.set_room(room)
    @socket.clear_messages

    {:ok, %{session: :session, socket: :socket, user: %{id: 1, name: "Player"}}}
  end

  test "set your target from someone in the room", %{session: session, socket: socket, user: user} do
    {:update, state} = Game.Command.Target.run({"bandit"}, session, %{socket: socket, user: user, save: %{room_id: 1}})

    assert state.target == {:npc, 1}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look) 
  end

  test "targeting another player", %{session: session, socket: socket, user: user} do
    {:update, state} = Game.Command.Target.run({"player"}, session, %{socket: socket, user: user, save: %{room_id: 1}})

    assert state.target == {:user, 2}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look) 
  end

  test "cannot target another player if health is < 1", %{session: session, socket: socket, user: user} do
    room = @room._room()
    |> Map.put(:npcs, [])
    |> Map.put(:players, [%{id: 2, name: "Player", save: %{stats: %{health: -1}}}])
    @room.set_room(room)

    :ok = Game.Command.Target.run({"player"}, session, %{socket: socket, user: user, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be targeted), look) 
  end

  test "target not found", %{session: session, socket: socket, user: user} do
    :ok = Game.Command.Target.run({"unknown"}, session, %{socket: socket, user: user, save: %{room_id: 1}})

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
