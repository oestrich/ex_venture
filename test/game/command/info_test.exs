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
    user = %{name: "hero", save: base_save(), class: %{name: "Fighter"}}
    save = %{user.save | wearing: %{chest: armor.id}, stats: %{dexterity: 10, health: 50, max_health: 50, strength: 10}}

    Command.Info.run({}, session, %{socket: socket, user: user, save: save})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(hero), look)
    assert Regex.match?(~r(Strength: 20), look)
  end
end
