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
    @socket.clear_messages()

    %{state: session_state(%{user: base_user()})}
  end

  test "set your target from someone in the room", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "bandit"}, state)

    assert state.target == {:npc, 1}
    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{_socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "targeting another player", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "player"}, state)

    assert state.target == {:player, 2}
    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{_socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "targeting yourself", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "self"}, state)

    assert state.target == {:player, state.character.id}

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(now targeting), look)
    assert [{_socket, "Target.Character", _}] = @socket.get_push_gmcps()
  end

  test "cannot target another player if health is < 1", %{state: state} do
    room = @room._room()
    |> Map.put(:npcs, [])
    |> Map.put(:players, [%{id: 2, name: "Player", save: %{stats: %{health_points: -1}}}])
    @room.set_room(room)

    :ok = Game.Command.Target.run({:set, "player"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(could not be targeted), look)
  end

  test "target not found", %{state: state} do
    :ok = Game.Command.Target.run({:set, "unknown"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(not find), look)
  end

  test "viewing your target - npc", %{state: state} do
    state = %{state | target: {:npc, 1}}
    :ok = Game.Command.Target.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look)
  end

  test "viewing your target - npc no longer there", %{state: state} do
    state = %{state | target: {:npc, 2}}
    :ok = Game.Command.Target.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look)
  end

  test "viewing your target - palyer", %{state: state} do
    state = %{state | target: {:player, 2}}
    :ok = Game.Command.Target.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target is), look)
  end

  test "viewing your target - user no longer there", %{state: state} do
    state = %{state | target: {:player, 3}}
    :ok = Game.Command.Target.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not be found), look)
  end

  test "viewing your target - missing", %{state: state} do
    state = %{state | target: nil}
    :ok = Game.Command.Target.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have a target), look)
  end
end
