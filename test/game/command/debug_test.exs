defmodule Game.Command.DebugTest do
  use Data.ModelCase
  doctest Game.Command.Debug

  alias Game.Command.Debug

  @socket Test.Networking.Socket

  describe "list debug information for admins" do
    setup do
      user = %{flags: ["admin"]}

      %{state: %{user: user, socket: :socket}}
    end

    test "displays debug information", %{state: state} do
      :ok = Debug.run({:squabble}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Node)i, echo)
    end

    test "must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Debug.run({:squabble}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(must be an admin)i, echo)
    end
  end

  describe "list player information for admins" do
    setup do
      user = %{flags: ["admin"]}

      %{state: %{user: user, socket: :socket}}
    end

    test "displays debug information", %{state: state} do
      :ok = Debug.run({:players}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(Players)i, echo)
    end

    test "must be an admin", %{state: state} do
      state = %{state | user: %{state.user | flags: []}}

      :ok = Debug.run({:players}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(must be an admin)i, echo)
    end
  end
end
