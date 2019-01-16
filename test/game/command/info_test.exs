defmodule Game.Command.InfoTest do
  use ExVenture.CommandCase

  alias Game.Command.Info

  doctest Info

  describe "viewing your information" do
    setup do
      armor = %{id: 1, effects: [%{kind: "stats", mode: "add", field: :strength, amount: 10}]}
      start_and_clear_items()
      insert_item(armor)

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      %{state: session_state(%{user: user, character: character}), armor: armor}
    end

    test "view room information", %{state: state, armor: armor} do
      save = %{state.character.save | wearing: %{chest: armor.id}, stats: base_stats()}
      ten_min_ago = Timex.now() |> Timex.shift(minutes: -10)

      Info.run({}, %{state | save: save, session_started_at: ten_min_ago})

      assert_socket_echo ["hero", "strength.+|.+20", "skill points.+|.+10", "play time.+|.+00h 10m 15s"]
    end
  end

  describe "viewing another player" do
    setup do
      user = base_user()
      character = base_character(user)
      %{state: session_state(%{user: user, character: character})}
    end

    test "can see basic information", %{state: state} do
      create_user(%{name: "player", password: "password"})

      :ok = Info.run({"player"}, state)

      assert_socket_echo "player"
    end

    test "player not found", %{state: state} do
      :ok = Info.run({"player"}, state)

      assert_socket_echo "could not find"
    end
  end
end
