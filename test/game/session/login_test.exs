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
    state = Login.process("username", :session, %{socket: socket})

    assert state.login.username == "username"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "verifies the user's username and password", %{socket: socket} do
    user = create_user(%{username: "user", password: "password"})

    state = Login.process("password", :session, %{socket: socket, room_id: 1, login: %{username: "user"}})

    assert state.user.id == user.id
    assert state.state == "active"
    [{^socket, "\nWelcome, user!\n"} | _] = @socket.get_echos()
  end

  test "verifies the user's username and password - failure", %{socket: socket} do
    create_user(%{username: "user", password: "password"})

    state = Login.process("p@ssword", :session, %{socket: socket, login: %{username: "user"}})

    assert Map.has_key?(state, :user) == false
    assert @socket.get_echos() == [{socket, "Invalid password"}]
    assert @socket.get_disconnects() == [socket]
  end

  test "entering the username as 'create' will make a new account", %{socket: socket} do
    state = Login.process("create", :session, %{socket: socket})

    assert state.state == "create"
    assert @socket.get_prompts() == [{socket, "Username: "}]
  end
end
