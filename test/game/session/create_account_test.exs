defmodule Game.Session.CreateAccountTest do
  use ExUnit.Case
  use Data.ModelCase
  use Networking.SocketCase

  alias Game.Session.CreateAccount

  setup do
    human = create_race()
    fighter = create_class()
    %{race: human, class: fighter}
  end

  test "start creating an account", %{socket: socket} do
    state = CreateAccount.process("user", :session, %{socket: socket})

    assert state.create.name == "user"
    assert @socket.get_prompts() == [{socket, "Race: "}]
  end

  test "pick a race", %{socket: socket, race: human} do
    state = CreateAccount.process("human", :session, %{socket: socket, create: %{name: "user"}})

    assert state.create.race == human
    assert @socket.get_prompts() == [{socket, "Class: "}]
  end

  test "picking a race again if a mistype", %{socket: socket} do
    state = CreateAccount.process("humn", :session, %{socket: socket, create: %{name: "user"}})

    refute Map.has_key?(state.create, :race)
    assert @socket.get_prompts() == [{socket, "Race: "}]
  end

  test "pick a class", %{socket: socket, race: human, class: fighter} do
    state = CreateAccount.process("fighter", :session, %{socket: socket, create: %{name: "user", race: human}})

    assert state.create.class == fighter
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "picking a class again if a mistype", %{socket: socket, race: human} do
    state = CreateAccount.process("figter", :session, %{socket: socket, create: %{name: "user", race: human}})

    refute Map.has_key?(state.create, :class)
    assert @socket.get_prompts() == [{socket, "Class: "}]
  end

  test "create the account after password is entered", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("password", :session, %{socket: socket, create: %{name: "user", race: human, class: fighter}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "Welcome, user!"}]
  end

  test "failure creating the account after entering the password", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, %{} |> Poison.encode!)
    state = CreateAccount.process("", :session, %{socket: socket, create: %{name: "user", race: human, class: fighter}})

    refute Map.has_key?(state, :create)
    assert @socket.get_echos() == [{socket, "There was a problem creating your account.\nPlease start over."}]
  end
end
