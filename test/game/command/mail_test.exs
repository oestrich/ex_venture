defmodule Game.Command.MailTest do
  use Data.ModelCase
  doctest Game.Command.Mail

  alias Game.Command.Mail

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    user = create_user(%{name: "user", password: "password"})
    %{session: :session, state: %{socket: :socket, user: user}}
  end

  describe "list out messages" do
    test "no messages", %{session: session, state: state} do
      :ok = Mail.run({}, session, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(no mail), mail)
    end

    test "includes messages", %{session: session, state: state} do
      sender = create_user(%{name: "sender", password: "password"})

      create_mail(sender, state.user, %{title: "hello"})

      {:paginate, mail, _state} = Mail.run({}, session, state)

      assert Regex.match?(~r(hello), mail)
    end
  end

  describe "reading single mail items" do
    setup do
      sender = create_user(%{name: "sender", password: "password"})
      %{sender: sender}
    end

    test "displays it", %{session: session, sender: sender, state: state} do
      mail = create_mail(sender, state.user, %{title: "hello"})

      {:paginate, mail, _state} = Mail.run({:read, mail.id}, session, state)

      assert Regex.match?(~r(hello), mail)
    end

    test "could not find mail", %{session: session, state: state} do
      :ok = Mail.run({:read, 10}, session, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(could not), mail)
    end

    test "trying to read someone else's mail", %{session: session, sender: sender, state: state} do
      other_user = create_user(%{name: "other", password: "password"})
      mail = create_mail(sender, other_user, %{title: "hello"})

      :ok = Mail.run({:read, mail.id}, session, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(could not), mail)
    end
  end
end
