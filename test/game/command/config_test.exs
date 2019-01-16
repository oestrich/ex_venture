defmodule Game.Command.ConfigTest do
  use ExVenture.CommandCase

  alias Game.Command.Config

  doctest Config

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    %{state: session_state(%{user: user, character: character, save: character.save})}
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

      assert_socket_echo "on"
    end

    test "cannot turn on settable config options - like pager_size", %{state: state} do
      :ok = Config.run({:on, "pager_size"}, state)

      assert_socket_echo "cannot"
    end

    test "the key is not found - skips", %{state: state} do
      :ok = Config.run({:on, "missing"}, state)

      assert_socket_echo "unknown"
    end
  end

  describe "config off" do
    test "set to false", %{state: state} do
      state = %{state | save: %{state.save | config: %{hints: true}}}

      {:update, %{save: save}} = Config.run({:off, "hints"}, state)

      refute save.config.hints

      assert_socket_echo "off"
    end

    test "cannot turn off settable config options - like pager_size", %{state: state} do
      :ok = Config.run({:off, "pager_size"}, state)

      assert_socket_echo "cannot"
    end

    test "the key is not found - skips", %{state: state} do
      :ok = Config.run({:off, "missing"}, state)

      assert_socket_echo "unknown"
    end
  end

  describe "config setting" do
    test "set to a string - prompt", %{state: state} do
      state = %{state | save: %{state.save | config: %{prompt: ""}}}

      {:update, %{save: save}} = Config.run({:set, "prompt %h/%Hhp"}, state)

      assert save.config.prompt == "%h/%Hhp"

      assert_socket_echo "set"
    end

    test "set to a color - color_npc", %{state: state} do
      state = %{state | save: %{state.save | config: %{prompt: ""}}}

      {:update, %{save: save}} = Config.run({:set, "color_npc green"}, state)

      assert save.config.color_npc == "green"

      assert_socket_echo "set"
    end

    test "set to an integer - pager_size", %{state: state} do
      state = %{state | save: %{state.save | config: %{pager_size: 20}}}

      {:update, %{save: save}} = Config.run({:set, "pager_size 25"}, state)

      assert save.config.pager_size == 25

      assert_socket_echo "set"
    end

    test "cannot set non-string config options - like hint", %{state: state} do
      :ok = Config.run({:set, "hints true"}, state)

      assert_socket_echo "cannot"
    end

    test "cannot set unknown config options", %{state: state} do
      :ok = Config.run({:set, "unknown hi"}, state)

      assert_socket_echo "unknown"
    end
  end
end
