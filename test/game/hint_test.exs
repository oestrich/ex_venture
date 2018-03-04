defmodule Game.HintTest do
  use ExUnit.Case

  alias Game.Hint

  @socket Test.Networking.Socket

  test "formats hints" do
    assert Hint.hint("quests.new", %{id: 10}) == "You can view this with {white}quest info 10{/white}"
  end

  describe "gating hints" do
    setup do
      @socket.clear_messages()
      :ok
    end

    test "config is on" do
      state = %{socket: :socket, save: %{config: %{hints: true}}}

      Hint.gate(state, "quests.new", id: 10)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/quest/, echo)
    end

    test "config is off" do
      state = %{save: %{config: %{hints: false}}}

      Hint.gate(state, "quests.new", id: 10)

      assert [] = @socket.get_echos()
    end
  end
end
