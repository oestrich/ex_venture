defmodule Game.Command.SkillsTest do
  use Data.ModelCase
  doctest Game.Command.Skills

  alias Game.Command

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    npc = %{id: 1, name: "Bandit"}

    room = @room._room()
    |> Map.put(:npcs, [npc])

    @room.set_room(room)
    @socket.clear_messages

    slash = %{
      level: 1,
      name: "Slash",
      points: 2,
      command: "slash",
      description: "Slash",
      user_text: "Slash at your {target}",
      usee_text: "You were slashed at",
      effects: [],
    }

    user = %{id: 10, name: "Player", class: %{name: "Fighter", points_abbreviation: "PP", skills: [slash]}}
    save = %{level: 1, stats: %{strength: 10, skill_points: 10}, wearing: %{}}
    {:ok, %{socket: :socket, user: user, save: save, slash: slash}}
  end

  test "view skill information", %{socket: socket, user: user, save: save} do
    :ok = Command.Skills.run({}, %{socket: socket, user: user, save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(slash), look)
    assert Regex.match?(~r(2PP), look)
  end

  test "using a skill", %{socket: socket, user: user, save: save, slash: slash} do
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}

    {:update, state} = Command.Skills.run({slash, "slash"}, state)
    assert state.save.stats.skill_points == 8

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - set your target", %{socket: socket, user: user, save: save, slash: slash} do
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: nil}

    {:update, state} = Command.Skills.run({slash, "slash bandit"}, state)
    assert state.save.stats.skill_points == 8
    assert state.target == {:npc, 1}

    [_, {^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - change your target", %{socket: socket, user: user, save: save, slash: slash} do
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:user, 3}}

    {:update, state} = Command.Skills.run({slash, "slash bandit"}, state)
    assert state.save.stats.skill_points == 8
    assert state.target == {:npc, 1}

    [_, {^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - target not found", %{socket: socket, user: user, save: save, slash: slash} do
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:npc, 2}}
    :ok = Command.Skills.run({slash, "slash"}, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not), look)
  end

  test "using a skill - with no target", %{socket: socket, user: user, slash: slash} do
    :ok = Command.Skills.run({slash, "slash"}, %{socket: socket, user: user, save: %{room_id: 1}, target: nil})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have), look)
  end

  test "using a skill - not enough skill points", %{socket: socket, user: user, save: save, slash: slash} do
    stats = %{save.stats | skill_points: 1}
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1, stats: stats}), target: {:npc, 1}}

    {:update, ^state} = Command.Skills.run({slash, "slash"}, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have), look)
  end

  test "using a skill - not high enough level", %{socket: socket, user: user, save: save, slash: slash} do
    state = %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}
    slash = %{slash | level: 2}

    :ok = Command.Skills.run({slash, "slash"}, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You are not high), look)
  end
end
