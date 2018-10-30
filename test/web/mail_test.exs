defmodule Web.MailTest do
  use Data.ModelCase

  alias Web.Mail

  describe "sending new mail" do
    setup do
      sender_user = create_user(%{name: "sender", password: "password"})
      sender = create_character(sender_user, %{name: "sender"})

      receiver_user = create_user(%{name: "receiver", password: "password"})
      receiver = create_character(receiver_user, %{name: "receiver"})

      %{sender: sender, receiver: receiver}
    end

    test "sends mail to the receiver by name", %{sender: sender, receiver: receiver} do
      {:ok, mail} = Mail.send(sender, %{
        "receiver_name" => receiver.name,
        "title" => "Title",
        "body" => "body"
      })

      assert mail.receiver_id == receiver.id
    end

    test "receiver not found", %{sender: sender} do
      {:error, :receiver, :not_found} = Mail.send(sender, %{
        "receiver_name" => "not found",
        "title" => "Title",
        "body" => "body"
      })
    end
  end
end
