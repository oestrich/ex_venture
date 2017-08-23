defmodule Game.Command.InfoTest do
  use Data.ModelCase

  alias Game.Command
  alias Game.Items

  @socket Test.Networking.Socket

  setup do
    Items.start_link
    armor = %{id: 1, effects: [%{kind: "stats", field: :strength, amount: 10}]}
    Agent.update(Items, fn (_) -> %{armor.id => armor} end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket, armor: armor}}
  end

  test "view room information", %{session: session, socket: socket, armor: armor} do
    user = %{name: "hero", save: base_save(), class: %{name: "Fighter", points_name: "Skill Points"}}
    stats = %{health: 50, max_health: 50, skill_points: 10, max_skill_points: 10, strength: 10, intelligence: 10, dexterity: 10}
    save = %{user.save | wearing: %{chest: armor.id}, stats: stats}

    Command.Info.run({}, session, %{socket: socket, user: user, save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(hero), look)
    assert Regex.match?(~r(Strength: 20), look)
    assert Regex.match?(~r(Skill Points: 10), look)
  end
end
