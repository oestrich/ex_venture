defmodule Game.Session.CreateAccountTest do
  use ExUnit.Case
  use Data.ModelCase
  use Networking.SocketCase

  alias Game.Session.CreateAccount

  test "start creating an account", %{socket: socket} do
    state = CreateAccount.process("user", %{socket: socket})

    assert state.create.username == "user"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "create the account after password is entered", %{socket: socket} do
    state = CreateAccount.process("password", %{socket: socket, create: %{username: "user"}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "Welcome, user"}]
  end

  test "failure creating the account after entering the password", %{socket: socket} do
    state = CreateAccount.process("", %{socket: socket, create: %{username: "user"}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "There was a problem creating your account.\nPlease start over."}]
  end
end
