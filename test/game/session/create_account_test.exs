defmodule Game.Session.CreateAccountTest do
  use ExUnit.Case
  use ExVenture.SessionCase

  alias Game.Session.CreateAccount
  alias Game.Session.State

  setup do
    human = create_race()
    fighter = create_class()

    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
    }

    %{state: state, race: human, class: fighter}
  end

  test "start creating an account by entering a name", %{state: state} do
    state = CreateAccount.process("user", state)

    assert state.create.name == "user"

    assert_socket_prompt "race:"
  end

  test "displays an error if name has a space", %{state: state} do
    CreateAccount.process("user name", state)

    assert_socket_prompt "name:"
  end

  test "pick a race", %{state: state, race: human} do
    state = CreateAccount.process("human", %{state | create: %{name: "user"}})

    assert state.create.race == human
    assert_socket_prompt "class:"
  end

  test "picking a race again if a mistype", %{state: state} do
    state = CreateAccount.process("humn", %{state | create: %{name: "user"}})

    refute Map.has_key?(state.create, :race)
    assert_socket_prompt "race:"
  end

  test "pick a class", %{state: state, race: human, class: fighter} do
    state = CreateAccount.process("fighter", %{state | create: %{name: "user", race: human}})

    assert state.create.class == fighter
    assert_socket_prompt "email"
  end

  test "picking a class again if a mistype", %{state: state, race: human} do
    state = CreateAccount.process("figter", %{state | create: %{name: "user", race: human}})

    refute Map.has_key?(state.create, :class)
    assert_socket_prompt "class:"
  end

  test "ask for an optional email", %{state: state, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("user@example.com", %{state | create: %{name: "user", race: human, class: fighter}})

    assert state.create.email == "user@example.com"
    assert_socket_prompt "password:"
  end

  test "ask for an optional email - give none", %{state: state, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("", %{state | create: %{name: "user", race: human, class: fighter}})

    assert state.create.email == ""
    assert_socket_prompt "password:"
  end

  test "request email again if it doesn't have an @ sign", %{state: state, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)

    state = CreateAccount.process("userexample.com", %{state | create: %{name: "user", race: human, class: fighter}})

    refute Map.has_key?(state.create, :email)
    assert_socket_prompt "email"
  end

  test "create the account after password is entered", %{state: state, race: human, class: fighter} do
    create_config(:starting_save, base_save() |> Poison.encode!)
    create_config(:after_sign_in_message, "Hi")

    state = CreateAccount.process("password", %{state | create: %{name: "user", email: "", race: human, class: fighter}})

    refute Map.has_key?(state, :create)

    assert_socket_echo "welcome"
    assert_socket_echo "press enter"
  end

  test "failure creating the account after entering the password", %{state: state, race: human, class: fighter} do
    create_config(:starting_save, %{} |> Poison.encode!)
    state = CreateAccount.process("", %{state | create: %{name: "user", email: "", race: human, class: fighter}})

    refute Map.has_key?(state, :create)

    assert_socket_echo "there was a problem"
  end
end
