defmodule Game.Command.SkillsTest do
  use Data.ModelCase
  doctest Game.Command.Skills

  alias Game.Command.Skills
  alias Game.Session.State

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    npc = %{id: 1, name: "Bandit"}

    room = @room._room()
    |> Map.put(:npcs, [npc])

    @room.set_room(room)
    @socket.clear_messages
    start_and_clear_skills()

    slash = create_skill(%{
      level: 1,
      name: "Slash",
      points: 2,
      command: "slash",
      description: "Slash",
      user_text: "Slash at your {target}",
      usee_text: "You were slashed at",
      effects: [],
    })
    insert_skill(slash)

    save = %{level: 1, stats: %{strength: 10, skill_points: 10}, wearing: %{}, skill_ids: [slash.id]}
    user = %{id: 10, name: "Player", save: save}

    state = %State{socket: :socket, state: "active", mode: "commands", user: user, save: save}

    {:ok, %{state: state, user: user, save: save, slash: slash}}
  end

  test "parsing skills based on the user", %{state: state, slash: slash} do
    assert %{text: "slash", module: Skills, args: {^slash, "slash"}} = Skills.parse_skill("slash", state.user)
    assert {:error, :bad_parse, "look"} = Skills.parse_skill("look", state.user)
  end

  test "view skill information", %{state: state} do
    :ok = Skills.run({}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(slash), look)
    assert Regex.match?(~r(2sp), look)
  end

  test "using a skill", %{state: state, save: save, slash: slash} do
    state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}

    {:update, state} = Skills.run({slash, "slash"}, state)
    assert state.save.stats.skill_points == 8

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - set your target", %{state: state, save: save, slash: slash} do
    state = %{state | save: Map.merge(save, %{room_id: 1}), target: nil}

    {:update, state} = Skills.run({slash, "slash bandit"}, state)
    assert state.save.stats.skill_points == 8
    assert state.target == {:npc, 1}

    [_, {_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - change your target", %{state: state, save: save, slash: slash} do
    state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:user, 3}}

    {:update, state} = Skills.run({slash, "slash bandit"}, state)
    assert state.save.stats.skill_points == 8
    assert state.target == {:npc, 1}

    [_, {_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - target not found", %{state: state, save: save, slash: slash} do
    state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 2}}
    :ok = Skills.run({slash, "slash"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not), look)
  end

  test "using a skill - with no target", %{state: state, slash: slash} do
    :ok = Skills.run({slash, "slash"}, %{state | target: nil})

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have), look)
  end

  test "using a skill - not enough skill points", %{state: state, save: save, slash: slash} do
    stats = %{save.stats | skill_points: 1}
    state = %{state | save: Map.merge(save, %{room_id: 1, stats: stats}), target: {:npc, 1}}

    {:update, ^state} = Skills.run({slash, "slash"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have), look)
  end

  test "using a skill - not high enough level", %{state: state, save: save, slash: slash} do
    state = %{state |save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}
    slash = %{slash | level: 2}

    :ok = Skills.run({slash, "slash"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You are not high), look)
  end
end
