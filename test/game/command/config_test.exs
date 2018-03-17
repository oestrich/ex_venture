defmodule Game.Command.ConfigTest do
  use Data.ModelCase
  doctest Game.Command.Config

  alias Game.Command.Config

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user, save: user.save}}
  end

  describe "listing config" do
    test "view all config", %{state: state} do
      {:paginate, echo, _state} = Config.run({:list}, state)

      assert Regex.match?(~r/hints/i, echo)
    end
  end

  describe "config on" do
    test "set to true", %{state: state} do
      state = %{state | save: %{state.save | config: %{hints: false}}}

      {:update, %{save: save}} = Config.run({:on, "hints"}, state)

      assert save.config.hints

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/on/, echo)
    end

    test "the key is not found - skips", %{state: state} do
      :ok = Config.run({:on, "missing"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/unknown/i, echo)
    end
  end

  describe "config off" do
    test "set to false", %{state: state} do
      state = %{state | save: %{state.save | config: %{hints: true}}}

      {:update, %{save: save}} = Config.run({:off, "hints"}, state)

      refute save.config.hints

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/off/, echo)
    end

    test "the key is not found - skips", %{state: state} do
      :ok = Config.run({:off, "missing"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/unknown/i, echo)
    end
  end

  describe "config setting" do
    test "set to a string - prompt", %{state: state} do
      state = %{state | save: %{state.save | config: %{prompt: ""}}}

      {:update, %{save: save}} = Config.run({:set, "prompt %h/%Hhp"}, state)

      assert save.config.prompt == "%h/%Hhp"

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/set/, echo)
    end

    test "set to an integer - pager_size", %{state: state} do
      state = %{state | save: %{state.save | config: %{pager_size: 20}}}

      {:update, %{save: save}} = Config.run({:set, "pager_size 25"}, state)

      assert save.config.pager_size == 25

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/set/, echo)
    end

    test "cannot set non-string config options - like hint", %{state: state} do
      :ok = Config.run({:set, "hints true"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/cannot/i, echo)
    end

    test "cannot set unknown config options", %{state: state} do
      :ok = Config.run({:set, "unknown hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/unknown/i, echo)
    end
  end
end
