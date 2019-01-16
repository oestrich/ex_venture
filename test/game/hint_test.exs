defmodule Game.HintTest do
  use ExUnit.Case

  import Test.Networking.Socket.Helpers

  alias Game.Hint

  test "formats hints" do
    assert Hint.hint("quests.new", %{id: 10}) == "You can view this with {command}quest info 10{/command}."
  end

  describe "gating hints" do
    test "config is on" do
      state = %{socket: :socket, save: %{config: %{hints: true}}}

      Hint.gate(state, "quests.new", id: 10)

      assert_socket_echo "quest"
    end

    test "config is off" do
      state = %{save: %{config: %{hints: false}}}

      Hint.gate(state, "quests.new", id: 10)

      refute_socket_echo()
    end
  end
end
