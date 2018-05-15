defmodule Web.ChatChannel do
  @moduledoc """
  User Channel for admins
  """

  use Phoenix.Channel

  alias Game.Command.Say
  alias Game.Channel
  alias Game.Channels
  alias Game.Message
  alias Web.User

  def join("chat:" <> channel, _message, socket) do
    %{user_id: user_id} = socket.assigns

    case User.get(user_id) do
      nil ->
        {:error, %{reason: "not found"}}
      user ->
        socket =
          socket
          |> assign(:channel, channel)
          |> assign(:user, user)

        {:ok, socket}
    end
  end

  def handle_in("send", %{"message" => message}, socket) do
    %{channel: channel, user: user} = socket.assigns

    case Channels.get(channel) do
      nil ->
        {:noreply, socket}

      channel ->
        parsed_message = Say.parse_message(message)
        Channel.broadcast(channel.name, Message.broadcast(user, channel, parsed_message))

        {:noreply, socket}
    end
  end
end
