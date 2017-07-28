defmodule Game.Session.CreateAccountTest do
  use ExUnit.Case
  use Data.ModelCase
  use Networking.SocketCase

  alias Game.Session.CreateAccount

  test "start creating an account", %{socket: socket} do
    state = CreateAccount.process("user", :session, %{socket: socket})

    assert state.create.name == "user"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "create the account after password is entered", %{socket: socket} do
    create_config(:starting_save, %{room_id: 1} |> Poison.encode!)

    state = CreateAccount.process("password", :session, %{socket: socket, create: %{name: "user"}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "Welcome, user!"}]
  end

  test "failure creating the account after entering the password", %{socket: socket} do
    state = CreateAccount.process("", :session, %{socket: socket, create: %{name: "user"}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "There was a problem creating your account.\nPlease start over."}]
  end
end
