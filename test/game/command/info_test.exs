defmodule Game.Command.InfoTest do
  use Data.ModelCase
  doctest Game.Command.Info

  alias Game.Command.Info

  @socket Test.Networking.Socket

  describe "viewing your information" do
    setup do
      armor = %{id: 1, effects: [%{kind: "stats", mode: "add", field: :strength, amount: 10}]}
      start_and_clear_items()
      insert_item(armor)

      @socket.clear_messages()

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      %{state: session_state(%{user: user, character: character}), armor: armor}
    end

    test "view room information", %{state: state, armor: armor} do
      save = %{state.character.save | wearing: %{chest: armor.id}, stats: base_stats()}
      ten_min_ago = Timex.now() |> Timex.shift(minutes: -10)

      Info.run({}, %{state | save: save, session_started_at: ten_min_ago})

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(hero), look)
      assert Regex.match?(~r(Strength.+|.+20), look)
      assert Regex.match?(~r(Skill Points.+|.+10), look)
      assert Regex.match?(~r(Play Time.+|.+00h 10m 15s), look)
    end
  end

  describe "viewing another player" do
    setup do
      @socket.clear_messages()

      user = base_user()
      character = base_character(user)
      %{state: session_state(%{user: user, character: character})}
    end

    test "can see basic information", %{state: state} do
      create_user(%{name: "player", password: "password"})

      :ok = Info.run({"player"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(player), echo)
    end

    test "player not found", %{state: state} do
      :ok = Info.run({"player"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(could not find)i, echo)
    end
  end
end
