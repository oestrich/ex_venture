defmodule Game.Session.LoginTest do
  use ExVenture.SessionCase

  alias Game.Session.Login
  alias Game.Session.Registry
  alias Game.Session.State

  setup do
    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
    }

    %{state: state}
  end

  test "start signing in", %{state: state} do
    state = Login.process("name", %{state | id: UUID.uuid4()})

    assert state.login.name == "name"
  end

  test "entering the name as 'create' will make a new account", %{state: state} do
    state = Login.process("create", state)

    assert state.state == "create"
    assert_socket_prompt "name:"
  end

  test "a session already exists", %{state: state} do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user, %{name: "user"})
    character = Repo.preload(character, [:race, :class])
    Registry.register(character)

    state = Login.sign_in(character.id, %{state | login: %{name: "user"}})

    refute state.user
    assert_socket_echo "player is already logged in"
    assert_socket_disconnect()

    Registry.unregister()
  end

  test "user has been disabled", %{state: state} do
    user = create_user(%{name: "user", password: "password", flags: ["disabled"]})
    user = set_user_flags(user, ["disabled"])
    character = create_character(user, %{name: "user"})

    state = Login.sign_in(character.id, %{state | login: %{name: "user"}})

    refute state.user
    assert_socket_echo "has been disabled"
    assert_socket_disconnect()
  end
end
