defmodule Game.Command.DebugTest do
  use ExVenture.CommandCase

  alias Game.Command.Debug

  doctest Debug

  describe "list debug information for admins" do
    setup do
      user = %{flags: ["admin"]}

      %{state: %{user: user, socket: :socket}}
    end

    test "displays debug information", %{state: state} do
      :ok = Debug.run({:squabble}, state)

      assert_socket_echo "node"
    end

    test "must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Debug.run({:squabble}, state)

      assert_socket_echo "must be an admin"
    end
  end

  describe "list player information for admins" do
    setup do
      user = %{flags: ["admin"]}

      %{state: %{user: user, socket: :socket}}
    end

    test "displays debug information", %{state: state} do
      :ok = Debug.run({:players}, state)

      assert_socket_echo "players"
    end

    test "must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Debug.run({:players}, state)

      assert_socket_echo "must be an admin"
    end
  end
end
