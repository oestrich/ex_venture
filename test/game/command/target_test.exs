defmodule Game.Command.TargetTest do
  use ExVenture.CommandCase

  alias Game.Command.Target

  doctest Target

  setup do
    npc = %{id: 1, name: "Bandit"}

    start_room(%{
      npcs: [npc],
      players: [%{id: 2, name: "Player", save: %{stats: %{health_points: 1}}}]
    })

    user = base_user()
    character = base_character(user)

    %{state: session_state(%{user: user, character: character})}
  end

  test "set your target from someone in the room", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "bandit"}, state)

    assert state.target == {:npc, 1}

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "targeting another player", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "player"}, state)

    assert state.target == {:player, 2}

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "targeting yourself", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "self"}, state)

    assert state.target == {:player, state.character.id}

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "cannot target another player if health is < 1", %{state: state} do
    start_room(%{
      npcs: [],
      players: [%{id: 2, name: "Player", save: %{stats: %{health_points: -1}}}]
    })

    :ok = Game.Command.Target.run({:set, "player"}, state)

    assert_socket_echo "could not"
  end

  test "target not found", %{state: state} do
    :ok = Game.Command.Target.run({:set, "unknown"}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - npc", %{state: state} do
    state = %{state | target: {:npc, 1}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "your target is"
  end

  test "viewing your target - npc no longer there", %{state: state} do
    state = %{state | target: {:npc, 2}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - player", %{state: state} do
    state = %{state | target: {:player, 2}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "your target is"
  end

  test "viewing your target - user no longer there", %{state: state} do
    state = %{state | target: {:player, 3}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - missing", %{state: state} do
    state = %{state | target: nil}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "don't have"
  end
end
