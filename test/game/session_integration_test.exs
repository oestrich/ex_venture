defmodule Game.SessionIntegrationTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    {:ok, %{socket: socket}}
  end

  test "when started asks for login information", %{socket: socket} do
    create_user(%{username: "user", password: "password"})

    {:ok, pid} = Session.start_link(socket)

    [{^socket, welcome_text}] = @socket.get_echos()
    assert String.starts_with?(welcome_text, "Welcome")
    assert @socket.get_prompts() == [{socket, "What is your player name? "}]
    @socket.clear_messages

    Session.recv(pid, "user")
    wait_cast(pid)

    assert @socket.get_prompts() == [{socket, "Password: "}]
    @socket.clear_messages

    Session.recv(pid, "password")
    wait_cast(pid)

    assert [{^pid, _user}] = Registry.lookup(Session.Registry, "player")
    assert @socket.get_echos() == [{socket, "Welcome, user"}]
  end
end
