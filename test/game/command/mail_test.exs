defmodule Game.Command.MailTest do
  use Data.ModelCase
  doctest Game.Command.Mail

  alias Game.Command.Mail

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user}}
  end

  describe "list out messages" do
    test "no messages", %{state: state} do
      :ok = Mail.run({:unread}, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(no unread mail), mail)
    end

    test "includes messages", %{state: state} do
      sender = create_user(%{name: "sender", password: "password"})

      create_mail(sender, state.user, %{title: "hello"})

      {:paginate, mail, _state} = Mail.run({:unread}, state)

      assert Regex.match?(~r(hello), mail)
    end
  end

  describe "reading single mail items" do
    setup do
      sender = create_user(%{name: "sender", password: "password"})
      %{sender: sender}
    end

    test "displays it and marks as read", %{sender: sender, state: state} do
      mail = create_mail(sender, state.user, %{title: "hello"})

      {:paginate, mail_text, _state} = Mail.run({:read, mail.id}, state)

      assert Regex.match?(~r(hello), mail_text)
      mail = Data.Repo.get(Data.Mail, mail.id)
      assert mail.is_read
    end

    test "could not find mail", %{state: state} do
      :ok = Mail.run({:read, 10}, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(could not), mail)
    end

    test "trying to read someone else's mail", %{sender: sender, state: state} do
      other_user = create_user(%{name: "other", password: "password"})
      mail = create_mail(sender, other_user, %{title: "hello"})

      :ok = Mail.run({:read, mail.id}, state)

      [{_, mail}] = @socket.get_echos()
      assert Regex.match?(~r(could not), mail)
    end
  end
end
