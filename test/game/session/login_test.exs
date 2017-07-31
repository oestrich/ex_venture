defmodule Game.Session.LoginTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session.Login

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    {:ok, %{socket: socket}}
  end

  test "start signing in", %{socket: socket} do
    state = Login.process("name", :session, %{socket: socket})

    assert state.login.name == "name"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "verifies the user's name and password", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})

    state = Login.process("password", :session, %{socket: socket, room_id: 1, login: %{name: "user"}})

    assert state.user.id == user.id
    assert state.state == "active"
    [{^socket, "Welcome, user!"} | _] = @socket.get_echos()
  end

  test "verifies the user's name and password - failure", %{socket: socket} do
    create_user(%{name: "user", password: "password"})

    state = Login.process("p@ssword", :session, %{socket: socket, login: %{name: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Invalid password"}]
    assert @socket.get_disconnects() == [socket]
  end

  test "entering the name as 'create' will make a new account", %{socket: socket} do
    state = Login.process("create", :session, %{socket: socket})

    assert state.state == "create"
    assert @socket.get_prompts() == [{socket, "Name: "}]
  end
end
