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
    case Map.has_key?(socket.assigns, :user_id) do
      true ->
        assign_user(socket, channel)

      false ->
        {:error, %{reason: "user required"}}
    end
  end

  defp assign_user(socket, channel) do
    %{user_id: user_id} = socket.assigns

    case User.get(user_id) do
      nil ->
        {:error, %{reason: "not found"}}

      user ->
        socket
        |> assign(:user, user)
        |> assign_channel(channel)
    end
  end

  defp assign_channel(socket, channel) do
    case Channels.get(channel) do
      nil ->
        {:error, %{reason: "no such channel"}}

      channel ->
        socket = assign(socket, :channel, channel)
        {:ok, socket}
    end
  end

  def handle_in("send", %{"message" => message}, socket) do
    %{channel: channel, user: user} = socket.assigns

    parsed_message = Say.parse_message(message)
    Channel.broadcast(channel.name, Message.broadcast(user, channel, parsed_message))

    {:noreply, socket}
  end
end
