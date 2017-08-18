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
      name: "Slash",
      points: 2,
      command: "slash",
      description: "Slash",
      user_text: "Slash at your {target}",
      usee_text: "You were slashed at",
      effects: [],
    }

    user = %{id: 10, name: "Player", class: %{name: "Fighter", points_abbreviation: "PP", skills: [slash]}}
    save = %{stats: %{strength: 10}, wearing: %{}}
    {:ok, %{session: :session, socket: :socket, user: user, save: save, slash: slash}}
  end

  test "view skill information", %{session: session, socket: socket, user: user} do
    Command.Skills.run({}, session, %{socket: socket, user: user})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(slash), look)
    assert Regex.match?(~r(2PP), look)
  end

  test "using a skill", %{session: session, socket: socket, user: user, save: save, slash: slash} do
    Command.Skills.run({slash, "slash"}, session, %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Slash), look)
  end

  test "using a skill - target not found", %{session: session, socket: socket, user: user, save: save, slash: slash} do
    Command.Skills.run({slash, "slash"}, session, %{socket: socket, user: user, save: Map.merge(save, %{room_id: 1}), target: {:npc, 2}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Your target could not), look)
  end

  test "using a skill - with no target", %{session: session, socket: socket, user: user, slash: slash} do
    Command.Skills.run({slash, "slash"}, session, %{socket: socket, user: user, save: %{room_id: 1}, target: nil})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You don't have), look)
  end
end
