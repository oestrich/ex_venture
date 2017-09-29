defmodule Game.Command.InfoTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    armor = %{id: 1, effects: [%{kind: "stats", field: :strength, amount: 10}]}
    start_and_clear_items()
    insert_item(armor)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket, armor: armor}}
  end

  test "view room information", %{session: session, socket: socket, armor: armor} do
    user = %{
      name: "hero",
      save: base_save(),
      race: %{name: "Human"},
      class: %{name: "Fighter", points_name: "Skill Points"},
      seconds_online: 15,
    }
    save = %{user.save | wearing: %{chest: armor.id}, stats: base_stats()}
    ten_min_ago = Timex.now() |> Timex.shift(minutes: -10)

    Command.Info.run({}, session, %{socket: socket, user: user, save: save, session_started_at: ten_min_ago})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(hero), look)
    assert Regex.match?(~r(Strength.+|.+20), look)
    assert Regex.match?(~r(Skill Points.+|.+10), look)
    assert Regex.match?(~r(Play Time.+|.+00h 10m 15s), look)
  end
end
