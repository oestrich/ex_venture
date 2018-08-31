defmodule Game.Command.TargetTest do
  use Data.ModelCase
  doctest Game.Command.Target

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    npc = %{id: 1, name: "Bandit"}

    room = @room._room()
    |> Map.put(:npcs, [npc])
    |> Map.put(:players, [%{id: 2, name: "Player", save: %{stats: %{health_points: 1}}}])

    @room.set_room(room)
    @socket.clear_messages

    {:ok, %{socket: :socket, user: %{id: 1, name: "Player"}}}
  end

  test "set your target from someone in the room", %{socket: socket, user: user} do
    {:update, state} = Game.Command.Target.run({"bandit"}, %{socket: socket, user: user, save: %{room_id: 1}})

    assert state.target == {:npc, 1}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{^socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "targeting another player", %{socket: socket, user: user} do
    {:update, state} = Game.Command.Target.run({"player"}, %{socket: socket, user: user, save: %{room_id: 1}})

    assert state.target == {:player, 2}
    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{^socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "targeting yourself", %{socket: socket, user: user} do
    {:update, state} = Game.Command.Target.run({"self"}, %{socket: socket, user: user, save: %{room_id: 1}})

    assert state.target == {:player, user.id}

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{^socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "cannot target another player if health is < 1", %{socket: socket, user: user} do
    room = @room._room()
    |> Map.put(:npcs, [])
    |> Map.put(:players, [%{id: 2, name: "Player", save: %{stats: %{health_points: -1}}}])
    @room.set_room(room)

    :ok = Game.Command.Target.run({"player"}, %{socket: socket, user: user, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be targeted), look)
  end

  test "target not found", %{socket: socket, user: user} do
    :ok = Game.Command.Target.run({"unknown"}, %{socket: socket, user: user, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(not find), look)
  end

  test "viewing your target - npc", %{socket: socket} do
    :ok = Game.Command.Target.run({}, %{socket: socket, save: %{room_id: 1}, target: {:npc, 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look)
  end

  test "viewing your target - npc no longer there", %{socket: socket} do
    :ok = Game.Command.Target.run({}, %{socket: socket, save: %{room_id: 1}, target: {:npc, 2}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look)
  end

  test "viewing your target - user", %{socket: socket} do
    :ok = Game.Command.Target.run({}, %{socket: socket, save: %{room_id: 1}, target: {:player, 2}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look)
  end

  test "viewing your target - user no longer there", %{socket: socket} do
    :ok = Game.Command.Target.run({}, %{socket: socket, save: %{room_id: 1}, target: {:player, 3}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look)
  end

  test "viewing your target - missing", %{socket: socket} do
    :ok = Game.Command.Target.run({}, %{socket: socket, save: %{room_id: 1}, target: nil})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have a target), look)
  end
end
