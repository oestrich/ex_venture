defmodule Game.Command.CrashTest do
  use ExVenture.CommandCase

  alias Game.Command.Crash

  doctest Crash

  @room Test.Game.Room

  setup do
    @room.clear_crashes()

    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    %{state: %{socket: :socket, user: user, save: %{room_id: 10}}}
  end

  describe "crashing a room" do
    test "sends a signal to crash the room you are in", %{state: state} do
      :ok = Crash.run({:room}, state)

      assert_receive {:echo, _, message}
      assert Regex.match?(~r(crash)i, message)

      assert [10] == @room.get_crashes()
    end

    test "you must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Crash.run({:room}, state)

      assert_receive {:echo, _, message}
      assert Regex.match?(~r(must be an admin)i, message)

      assert [] == @room.get_crashes()
    end
  end
end
