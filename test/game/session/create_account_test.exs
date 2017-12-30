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

  test "start creating an account by entering a name", %{socket: socket} do
    state = CreateAccount.process("user", :session, %{socket: socket})

    assert state.create.name == "user"
    assert @socket.get_prompts() == [{socket, "Race: "}]
  end

  test "displays an error if name has a space", %{socket: socket} do
    %{socket: socket} = CreateAccount.process("user name", :session, %{socket: socket})

    assert @socket.get_prompts() == [{socket, "Name: "}]
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
    assert @socket.get_prompts() == [{socket, "Email (optional, enter for blank): "}]
  end

  test "picking a class again if a mistype", %{socket: socket, race: human} do
    state = CreateAccount.process("figter", :session, %{socket: socket, create: %{name: "user", race: human}})

    refute Map.has_key?(state.create, :class)
    assert @socket.get_prompts() == [{socket, "Class: "}]
  end

  test "ask for an optional email", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("user@example.com", :session, %{socket: socket, create: %{name: "user", race: human, class: fighter}})

    assert state.create.email == "user@example.com"
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "ask for an optional email - give none", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("", :session, %{socket: socket, create: %{name: "user", race: human, class: fighter}})

    assert state.create.email == ""
    assert @socket.get_prompts() == [{socket, "Password: "}]
  end

  test "request email again if it doesn't have an @ sign", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("userexample.com", :session, %{socket: socket, create: %{name: "user", race: human, class: fighter}})

    refute Map.has_key?(state.create, :email)
    assert @socket.get_prompts() == [{socket, "Email (optional, enter for blank): "}]
  end

  test "create the account after password is entered", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)
    create_config(:after_sign_in_message, "Hi")

    state = CreateAccount.process("password", :session, %{socket: socket, create: %{name: "user", email: "", race: human, class: fighter}})

    refute Map.has_key?(state, :create)
    [{^socket, "Welcome, user!"}, {^socket, "Hi"}, {^socket, "[Press enter to continue]"}] = @socket.get_echos()
  end

  test "failure creating the account after entering the password", %{socket: socket, race: human, class: fighter} do
    create_config(:starting_save, %{} |> Poison.encode!)
    state = CreateAccount.process("", :session, %{socket: socket, create: %{name: "user", email: "", race: human, class: fighter}})

    refute Map.has_key?(state, :create)
    assert [{^socket, "There was a problem creating your account.\nPlease start over." <> _}] = @socket.get_echos()
  end
end
