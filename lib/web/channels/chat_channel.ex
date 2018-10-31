defmodule Web.ChatChannel do
  @moduledoc """
  User Channel for admins
  """

  use Phoenix.Channel

  alias Game.Command.Say
  alias Game.Channel
  alias Game.Channels
  alias Game.Message
  alias Web.Channel, as: WebChannel
  alias Web.Character

  def join("chat:" <> channel, _message, socket) do
    case Map.has_key?(socket.assigns, :character_id) do
      true ->
        assign_character(socket, channel)

      false ->
        {:error, %{reason: "character required"}}
    end
  end

  defp assign_character(socket, channel) do
    %{character_id: character_id} = socket.assigns

    case Character.get_character(character_id) do
      {:ok, character} ->
        socket
        |> assign(:character, character)
        |> assign_channel(channel)

      {:error, :not_found} ->
        {:error, %{reason: "not found"}}
    end
  end

  defp assign_channel(socket, channel) do
    case Channels.get(channel) do
      nil ->
        {:error, %{reason: "no such channel"}}

      channel ->
        socket = assign(socket, :channel, channel)

        {:ok, WebChannel.recent_messages(channel), socket}
    end
  end

  def handle_in("send", %{"message" => message}, socket) do
    %{channel: channel, character: character} = socket.assigns

    parsed_message = Say.parse_message(message)
    Channel.broadcast(channel.name, Message.broadcast(character, channel, parsed_message))

    {:noreply, socket}
  end
end
