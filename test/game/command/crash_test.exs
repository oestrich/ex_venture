defmodule Game.Command.CrashTest do
  use ExVenture.CommandCase

  alias Game.Command.Crash

  doctest Crash

  setup do
    user = create_admin_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user, save: %{room_id: 10}}}
  end

  describe "crashing a room" do
    test "sends a signal to crash the room you are in", %{state: state} do
      :ok = Crash.run({:room}, state)

      assert_socket_echo "crash"
    end

    test "you must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Crash.run({:room}, state)

      assert_socket_echo "must be an admin"
    end
  end
end
