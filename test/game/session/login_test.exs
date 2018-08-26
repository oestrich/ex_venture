defmodule Game.Session.LoginTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session.Login
  alias Game.Session.Registry

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    {:ok, %{socket: socket}}
  end

  test "start signing in", %{socket: socket} do
    state = Login.process("name", %{id: UUID.uuid4(), socket: socket})

    assert state.login.name == "name"
    assert @socket.get_prompts() == []
  end

  test "entering the name as 'create' will make a new account", %{socket: socket} do
    state = Login.process("create", %{socket: socket})

    assert state.state == "create"
    assert @socket.get_prompts() == [{socket, "Name: "}]
  end

  test "a session already exists", %{socket: socket} do
    user = create_user(%{name: "user", password: "password", class_id: create_class().id})
    user = Repo.preload(user, [:race, :class])
    Registry.register(user)

    state = Login.sign_in(user.id, %{socket: socket, login: %{name: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Sorry, this player is already logged in."}]
    assert @socket.get_disconnects() == [socket]

    Registry.unregister()
  end

  test "user has been disabled", %{socket: socket} do
    user = create_user(%{name: "user", password: "password", class_id: create_class().id, flags: ["disabled"]})

    state = Login.sign_in(user.id, %{socket: socket, login: %{name: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Sorry, your account has been disabled. Please contact the admins."}]
    assert @socket.get_disconnects() == [socket]
  end
end
