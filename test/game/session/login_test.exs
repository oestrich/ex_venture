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
    state = Login.process("name", %{socket: socket})

    assert state.login.name == "name"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "verifies the user's name and password", %{socket: socket} do
    create_config("after_sign_in_message", "Hi")

    user = create_user(%{name: "user", password: "password", class_id: create_class().id})

    state = Login.process("password", %{socket: socket, room_id: 1, login: %{name: "user"}})

    assert state.user.id == user.id
    assert state.state == "after_sign_in"
    [{^socket, "Welcome, user!"}, {^socket, "Hi"}, {^socket, "[Press enter to continue]"}] = @socket.get_echos()
  end

  test "verifies the user's name and password - failure", %{socket: socket} do
    create_user(%{name: "user", password: "password", class_id: create_class().id})

    state = Login.process("p@ssword", %{socket: socket, login: %{name: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Invalid password"}]
    assert @socket.get_disconnects() == [socket]
  end

  test "entering the name as 'create' will make a new account", %{socket: socket} do
    state = Login.process("create", %{socket: socket})

    assert state.state == "create"
    assert @socket.get_prompts() == [{socket, "Name: "}]
  end

  test "a session already exists", %{socket: socket} do
    user = create_user(%{name: "user", password: "password", class_id: create_class().id})
    Registry.register(user)

    state = Login.process("password", %{socket: socket, login: %{name: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Sorry, this player is already logged in."}]
    assert @socket.get_disconnects() == [socket]

    Registry.unregister()
  end
end
