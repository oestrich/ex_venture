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

      @socket.clear_messages
      {:ok, %{socket: :socket, armor: armor}}
    end

    test "view room information", %{socket: socket, armor: armor} do
      user = %{
        name: "hero",
        save: base_save(),
        race: %{name: "Human"},
        class: %{name: "Fighter"},
        seconds_online: 15,
      }
      save = %{user.save | wearing: %{chest: armor.id}, stats: base_stats()}
      ten_min_ago = Timex.now() |> Timex.shift(minutes: -10)

      Info.run({}, %{socket: socket, user: user, save: save, session_started_at: ten_min_ago})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(hero), look)
      assert Regex.match?(~r(Strength.+|.+20), look)
      assert Regex.match?(~r(Skill Points.+|.+10), look)
      assert Regex.match?(~r(Play Time.+|.+00h 10m 15s), look)
    end
  end

  describe "viewing another player" do
    setup do
      @socket.clear_messages
      state = %{socket: :socket}
      %{state: state}
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
